/* Copyright (C) 2007-2012 Open Information Security Foundation
 *
 * You can copy, redistribute or modify this Program under the terms of
 * the GNU General Public License version 2 as published by the Free
 * Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * version 2 along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

/**
 * \file
 *
 * \author Endace Technology Limited.
 * \author Victor Julien <victor@inliniac.net>
 *
 * An API for profiling operations.
 *
 * Really just a wrapper around the existing perf counters.
 */

#include "suricata-common.h"
#include "decode.h"
#include "detect.h"
#include "conf.h"

#include "tm-threads.h"

#include "util-unittest.h"
#include "util-byte.h"
#include "util-profiling.h"
#include "util-profiling-locks.h"

#ifdef PROFILING

#ifndef MIN
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

#define DEFAULT_LOG_FILENAME "profile.log"
#define DEFAULT_LOG_MODE_APPEND "yes"

static pthread_mutex_t packet_profile_lock;
static FILE *packet_profile_csv_fp = NULL;

extern int profiling_locks_enabled;
extern int profiling_locks_output_to_file;
extern char *profiling_locks_file_name;
extern char *profiling_locks_file_mode;

typedef struct SCProfilePacketData_ {
    uint64_t min;
    uint64_t max;
    uint64_t tot;
    uint64_t cnt;
#ifdef PROFILE_LOCKING
    uint64_t lock;
    uint64_t ticks;
    uint64_t contention;

    uint64_t slock;
    uint64_t sticks;
    uint64_t scontention;
#endif
} SCProfilePacketData;
SCProfilePacketData packet_profile_data4[257]; /**< all proto's + tunnel */
SCProfilePacketData packet_profile_data6[257]; /**< all proto's + tunnel */

/* each module, each proto */
SCProfilePacketData packet_profile_tmm_data4[TMM_SIZE][257];
SCProfilePacketData packet_profile_tmm_data6[TMM_SIZE][257];

SCProfilePacketData packet_profile_app_data4[TMM_SIZE][257];
SCProfilePacketData packet_profile_app_data6[TMM_SIZE][257];

SCProfilePacketData packet_profile_app_pd_data4[257];
SCProfilePacketData packet_profile_app_pd_data6[257];

SCProfilePacketData packet_profile_detect_data4[PROF_DETECT_SIZE][257];
SCProfilePacketData packet_profile_detect_data6[PROF_DETECT_SIZE][257];

int profiling_packets_enabled = 0;
int profiling_packets_csv_enabled = 0;

int profiling_output_to_file = 0;
int profiling_packets_output_to_file = 0;
char *profiling_file_name;
char *profiling_packets_file_name;
char *profiling_csv_file_name;
const char *profiling_packets_file_mode = "a";

static int rate = 1;
static SC_ATOMIC_DECLARE(uint64_t, samples);

/**
 * Used as a check so we don't double enter a profiling run.
 */
__thread int profiling_rules_entered = 0;

void SCProfilingDumpPacketStats(void);
const char * PacketProfileDetectIdToString(PacketProfileDetectId id);

static void FormatNumber(uint64_t num, char *str, size_t size) {
    if (num < 1000UL)
        snprintf(str, size, "%"PRIu64, num);
    else if (num < 1000000UL)
        snprintf(str, size, "%3.1fk", (float)num/1000UL);
    else if (num < 1000000000UL)
        snprintf(str, size, "%3.1fm", (float)num/1000000UL);
    else
        snprintf(str, size, "%3.1fb", (float)num/1000000000UL);
}

/**
 * \brief Initialize profiling.
 */
void
SCProfilingInit(void)
{
    ConfNode *conf;

    SC_ATOMIC_INIT(samples);

    intmax_t rate_v = 0;
    (void)ConfGetInt("profiling.sample-rate", &rate_v);
    if (rate_v > 0 && rate_v < INT_MAX) {
        rate = (int)rate_v;
        if (rate != 1)
            SCLogInfo("profiling runs for every %dth packet", rate);
        else
            SCLogInfo("profiling runs for every packet");
    }

    conf = ConfGetNode("profiling.packets");
    if (conf != NULL) {
        if (ConfNodeChildValueIsTrue(conf, "enabled")) {
            profiling_packets_enabled = 1;

            if (pthread_mutex_init(&packet_profile_lock, NULL) != 0) {
                SCLogError(SC_ERR_MUTEX,
                        "Failed to initialize packet profiling mutex.");
                exit(EXIT_FAILURE);
            }
            memset(&packet_profile_data4, 0, sizeof(packet_profile_data4));
            memset(&packet_profile_data6, 0, sizeof(packet_profile_data6));
            memset(&packet_profile_tmm_data4, 0, sizeof(packet_profile_tmm_data4));
            memset(&packet_profile_tmm_data6, 0, sizeof(packet_profile_tmm_data6));
            memset(&packet_profile_app_data4, 0, sizeof(packet_profile_app_data4));
            memset(&packet_profile_app_data6, 0, sizeof(packet_profile_app_data6));
            memset(&packet_profile_app_pd_data4, 0, sizeof(packet_profile_app_pd_data4));
            memset(&packet_profile_app_pd_data6, 0, sizeof(packet_profile_app_pd_data6));
            memset(&packet_profile_detect_data4, 0, sizeof(packet_profile_detect_data4));
            memset(&packet_profile_detect_data6, 0, sizeof(packet_profile_detect_data6));

            const char *filename = ConfNodeLookupChildValue(conf, "filename");
            if (filename != NULL) {

                char *log_dir;
                log_dir = ConfigGetLogDirectory();

                profiling_packets_file_name = SCMalloc(PATH_MAX);
                if (unlikely(profiling_packets_file_name == NULL)) {
                    SCLogError(SC_ERR_MEM_ALLOC, "can't duplicate file name");
                    exit(EXIT_FAILURE);
                }

                snprintf(profiling_packets_file_name, PATH_MAX, "%s/%s", log_dir, filename);

                const char *v = ConfNodeLookupChildValue(conf, "append");
                if (v == NULL || ConfValIsTrue(v)) {
                    profiling_packets_file_mode = "a";
                } else {
                    profiling_packets_file_mode = "w";
                }

                profiling_packets_output_to_file = 1;
            }
        }

        conf = ConfGetNode("profiling.packets.csv");
        if (conf != NULL) {
            if (ConfNodeChildValueIsTrue(conf, "enabled")) {

                const char *filename = ConfNodeLookupChildValue(conf, "filename");
                if (filename == NULL) {
                    filename = "packet_profile.csv";
                }

                char *log_dir;
                log_dir = ConfigGetLogDirectory();

                profiling_csv_file_name = SCMalloc(PATH_MAX);
                if (unlikely(profiling_csv_file_name == NULL)) {
                    SCLogError(SC_ERR_MEM_ALLOC, "out of memory");
                    exit(EXIT_FAILURE);
                }
                snprintf(profiling_csv_file_name, PATH_MAX, "%s/%s", log_dir, filename);

                packet_profile_csv_fp = fopen(profiling_csv_file_name, "w");
                if (packet_profile_csv_fp == NULL) {
                    return;
                }
                fprintf(packet_profile_csv_fp, "pcap_cnt,ipver,ipproto,total,");
                int i;
                for (i = 0; i < TMM_SIZE; i++) {
                    fprintf(packet_profile_csv_fp, "%s,", TmModuleTmmIdToString(i));
                }
                fprintf(packet_profile_csv_fp, "threading,");
                for (i = 0; i < ALPROTO_MAX; i++) {
                    fprintf(packet_profile_csv_fp, "%s,", AppProtoToString(i));
                }
                fprintf(packet_profile_csv_fp, "STREAM (no app),proto detect,");
                for (i = 0; i < PROF_DETECT_SIZE; i++) {
                    fprintf(packet_profile_csv_fp, "%s,", PacketProfileDetectIdToString(i));
                }
                fprintf(packet_profile_csv_fp, "\n");

                profiling_packets_csv_enabled = 1;
            }
        }
    }

    conf = ConfGetNode("profiling.locks");
    if (conf != NULL) {
        if (ConfNodeChildValueIsTrue(conf, "enabled")) {
#ifndef PROFILE_LOCKING
            SCLogWarning(SC_WARN_PROFILE, "lock profiling not compiled in. Add --enable-profiling-locks to configure.");
#else
            profiling_locks_enabled = 1;

            LockRecordInitHash();

            const char *filename = ConfNodeLookupChildValue(conf, "filename");
            if (filename != NULL) {
                char *log_dir;
                log_dir = ConfigGetLogDirectory();

                profiling_locks_file_name = SCMalloc(PATH_MAX);
                if (unlikely(profiling_locks_file_name == NULL)) {
                    SCLogError(SC_ERR_MEM_ALLOC, "can't duplicate file name");
                    exit(EXIT_FAILURE);
                }

                snprintf(profiling_locks_file_name, PATH_MAX, "%s/%s", log_dir, filename);

                const char *v = ConfNodeLookupChildValue(conf, "append");
                if (v == NULL || ConfValIsTrue(v)) {
                    profiling_locks_file_mode = "a";
                } else {
                    profiling_locks_file_mode = "w";
                }

                profiling_locks_output_to_file = 1;
            }
#endif
        }
    }

}

/**
 * \brief Free resources used by profiling.
 */
void
SCProfilingDestroy(void)
{
    if (profiling_packets_enabled) {
        pthread_mutex_destroy(&packet_profile_lock);
    }

    if (profiling_packets_csv_enabled) {
        if (packet_profile_csv_fp != NULL)
            fclose(packet_profile_csv_fp);
    }

    if (profiling_csv_file_name != NULL)
        SCFree(profiling_csv_file_name);

    if (profiling_file_name != NULL)
        SCFree(profiling_file_name);

#ifdef PROFILE_LOCKING
    LockRecordFreeHash();
#endif
}

void
SCProfilingDump(void)
{
    SCProfilingDumpPacketStats();
    SCLogInfo("Done dumping profiling data.");
}

void SCProfilingDumpPacketStats(void) {
    int i;
    FILE *fp;
    char totalstr[256];
    uint64_t total;

    if (profiling_packets_enabled == 0)
        return;

    if (profiling_packets_output_to_file == 1) {
        fp = fopen(profiling_packets_file_name, profiling_packets_file_mode);

        if (fp == NULL) {
            SCLogError(SC_ERR_FOPEN, "failed to open %s: %s",
                    profiling_packets_file_name, strerror(errno));
            return;
        }
    } else {
       fp = stdout;
    }

    fprintf(fp, "\n\nPacket profile dump:\n");

    fprintf(fp, "\n%-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s\n",
            "IP ver", "Proto", "cnt", "min", "max", "avg", "tot", "%%");
    fprintf(fp, "%-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s\n",
            "------", "-----", "----------", "------------", "------------", "-----------", "-----------", "---");
    total = 0;
    for (i = 0; i < 257; i++) {
        SCProfilePacketData *pd = &packet_profile_data4[i];
        total += pd->tot;
        pd = &packet_profile_data6[i];
        total += pd->tot;
    }

    for (i = 0; i < 257; i++) {
        SCProfilePacketData *pd = &packet_profile_data4[i];

        if (pd->cnt == 0) {
            continue;
        }

        FormatNumber(pd->tot, totalstr, sizeof(totalstr));
        double percent = (long double)pd->tot /
            (long double)total * 100;

        fprintf(fp, " IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f\n", i, pd->cnt,
            pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
    }

    for (i = 0; i < 257; i++) {
        SCProfilePacketData *pd = &packet_profile_data6[i];

        if (pd->cnt == 0) {
            continue;
        }

        FormatNumber(pd->tot, totalstr, sizeof(totalstr));
        double percent = (long double)pd->tot /
            (long double)total * 100;

        fprintf(fp, " IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f\n", i, pd->cnt,
            pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
    }
    fprintf(fp, "Note: Protocol 256 tracks pseudo/tunnel packets.\n");

    fprintf(fp, "\nPer Thread module stats:\n");

    fprintf(fp, "\n%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s",
            "Thread Module", "IP ver", "Proto", "cnt", "min", "max", "avg", "tot", "%%");
#ifdef PROFILE_LOCKING
    fprintf(fp, "   %-10s   %-10s   %-12s   %-12s   %-10s   %-10s   %-12s   %-12s\n",
            "locks", "ticks", "cont.", "cont.avg", "slocks", "sticks", "scont.", "scont.avg");
#else
    fprintf(fp, "\n");
#endif
    fprintf(fp, "%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s",
            "------------------------", "------", "-----", "----------", "------------", "------------", "-----------", "-----------", "---");
#ifdef PROFILE_LOCKING
    fprintf(fp, "   %-10s   %-10s   %-12s   %-12s   %-10s   %-10s   %-12s   %-12s\n",
            "--------", "--------", "----------", "-----------", "--------", "--------", "------------", "-----------");
#else
    fprintf(fp, "\n");
#endif
    int m;
    total = 0;
    for (m = 0; m < TMM_SIZE; m++) {
        if (tmm_modules[m].flags & TM_FLAG_LOGAPI_TM)
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data4[m][p];
            total += pd->tot;

            pd = &packet_profile_tmm_data6[m][p];
            total += pd->tot;
        }
    }

    for (m = 0; m < TMM_SIZE; m++) {
        if (tmm_modules[m].flags & TM_FLAG_LOGAPI_TM)
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data4[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f",
                    TmModuleTmmIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
#ifdef PROFILE_LOCKING
            fprintf(fp, "  %10.2f  %12"PRIu64"  %12"PRIu64"  %10.2f  %10.2f  %12"PRIu64"  %12"PRIu64"  %10.2f\n",
                    (float)pd->lock/pd->cnt, (uint64_t)pd->ticks/pd->cnt, pd->contention, (float)pd->contention/pd->cnt, (float)pd->slock/pd->cnt, (uint64_t)pd->sticks/pd->cnt, pd->scontention, (float)pd->scontention/pd->cnt);
#else
            fprintf(fp, "\n");
#endif
        }
    }

    for (m = 0; m < TMM_SIZE; m++) {
        if (tmm_modules[m].flags & TM_FLAG_LOGAPI_TM)
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data6[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f\n",
                    TmModuleTmmIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }
    fprintf(fp, "Note: TMM_STREAMTCP includes TCP app layer parsers, see below.\n");

    fprintf(fp, "\nPer App layer parser stats:\n");

    fprintf(fp, "\n%-20s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s\n",
            "App Layer", "IP ver", "Proto", "cnt", "min", "max", "avg");
    fprintf(fp, "%-20s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s\n",
            "--------------------", "------", "-----", "----------", "------------", "------------", "-----------");

    total = 0;
    for (m = 0; m < ALPROTO_MAX; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_app_data4[m][p];
            total += pd->tot;

            pd = &packet_profile_app_data6[m][p];
            total += pd->tot;
        }
    }
    for (m = 0; m < ALPROTO_MAX; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_app_data4[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-20s    IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %-6.2f\n",
                    AppProtoToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }

    for (m = 0; m < ALPROTO_MAX; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_app_data6[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-20s    IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %-6.2f\n",
                    AppProtoToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }

    /* proto detect output */
    {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_app_pd_data4[p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            fprintf(fp, "%-20s    IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s\n",
                    "Proto detect", p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr);
        }

        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_app_pd_data6[p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            fprintf(fp, "%-20s    IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s\n",
                    "Proto detect", p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr);
        }
    }

    total = 0;
    for (m = 0; m < PROF_DETECT_SIZE; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_detect_data4[m][p];
            total += pd->tot;

            pd = &packet_profile_detect_data6[m][p];
            total += pd->tot;
        }
    }


    fprintf(fp, "\n%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s",
            "Log Thread Module", "IP ver", "Proto", "cnt", "min", "max", "avg", "tot", "%%");
#ifdef PROFILE_LOCKING
    fprintf(fp, "   %-10s   %-10s   %-12s   %-12s   %-10s   %-10s   %-12s   %-12s\n",
            "locks", "ticks", "cont.", "cont.avg", "slocks", "sticks", "scont.", "scont.avg");
#else
    fprintf(fp, "\n");
#endif
    fprintf(fp, "%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s  %-3s",
            "------------------------", "------", "-----", "----------", "------------", "------------", "-----------", "-----------", "---");
#ifdef PROFILE_LOCKING
    fprintf(fp, "   %-10s   %-10s   %-12s   %-12s   %-10s   %-10s   %-12s   %-12s\n",
            "--------", "--------", "----------", "-----------", "--------", "--------", "------------", "-----------");
#else
    fprintf(fp, "\n");
#endif
    total = 0;
    for (m = 0; m < TMM_SIZE; m++) {
        if (!(tmm_modules[m].flags & TM_FLAG_LOGAPI_TM))
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data4[m][p];
            total += pd->tot;

            pd = &packet_profile_tmm_data6[m][p];
            total += pd->tot;
        }
    }

    for (m = 0; m < TMM_SIZE; m++) {
        if (!(tmm_modules[m].flags & TM_FLAG_LOGAPI_TM))
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data4[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f",
                    TmModuleTmmIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
#ifdef PROFILE_LOCKING
            fprintf(fp, "  %10.2f  %12"PRIu64"  %12"PRIu64"  %10.2f  %10.2f  %12"PRIu64"  %12"PRIu64"  %10.2f\n",
                    (float)pd->lock/pd->cnt, (uint64_t)pd->ticks/pd->cnt, pd->contention, (float)pd->contention/pd->cnt, (float)pd->slock/pd->cnt, (uint64_t)pd->sticks/pd->cnt, pd->scontention, (float)pd->scontention/pd->cnt);
#else
            fprintf(fp, "\n");
#endif
        }
    }

    for (m = 0; m < TMM_SIZE; m++) {
        if (!(tmm_modules[m].flags & TM_FLAG_LOGAPI_TM))
            continue;

        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_tmm_data6[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %6.2f\n",
                    TmModuleTmmIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }

    fprintf(fp, "\nGeneral detection engine stats:\n");

    total = 0;
    for (m = 0; m < PROF_DETECT_SIZE; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_detect_data4[m][p];
            total += pd->tot;
            pd = &packet_profile_detect_data6[m][p];
            total += pd->tot;
        }
    }

    fprintf(fp, "\n%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s\n",
            "Detection phase", "IP ver", "Proto", "cnt", "min", "max", "avg", "tot");
    fprintf(fp, "%-24s   %-6s   %-5s   %-12s   %-12s   %-12s   %-12s   %-12s\n",
            "------------------------", "------", "-----", "----------", "------------", "------------", "-----------", "-----------");
    for (m = 0; m < PROF_DETECT_SIZE; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_detect_data4[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv4     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %-6.2f\n",
                    PacketProfileDetectIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }
    for (m = 0; m < PROF_DETECT_SIZE; m++) {
        int p;
        for (p = 0; p < 257; p++) {
            SCProfilePacketData *pd = &packet_profile_detect_data6[m][p];

            if (pd->cnt == 0) {
                continue;
            }

            FormatNumber(pd->tot, totalstr, sizeof(totalstr));
            double percent = (long double)pd->tot /
                (long double)total * 100;

            fprintf(fp, "%-24s    IPv6     %3d  %12"PRIu64"     %12"PRIu64"   %12"PRIu64"  %12"PRIu64"  %12s  %-6.2f\n",
                    PacketProfileDetectIdToString(m), p, pd->cnt, pd->min, pd->max, (uint64_t)(pd->tot / pd->cnt), totalstr, percent);
        }
    }
    fclose(fp);
}

void SCProfilingPrintPacketProfile(Packet *p) {
    if (profiling_packets_csv_enabled == 0 || p == NULL || packet_profile_csv_fp == NULL || p->profile == NULL) {
        return;
    }

    uint64_t delta = p->profile->ticks_end - p->profile->ticks_start;

    fprintf(packet_profile_csv_fp, "%"PRIu64",%c,%"PRIu8",%"PRIu64",",
            p->pcap_cnt, PKT_IS_IPV4(p) ? '4' : (PKT_IS_IPV6(p) ? '6' : '?'), p->proto,
            delta);

    int i;
    uint64_t tmm_total = 0;
    uint64_t tmm_streamtcp_tcp = 0;

    for (i = 0; i < TMM_SIZE; i++) {
        PktProfilingTmmData *pdt = &p->profile->tmm[i];

        uint64_t tmm_delta = pdt->ticks_end - pdt->ticks_start;
        fprintf(packet_profile_csv_fp, "%"PRIu64",", tmm_delta);
        tmm_total += tmm_delta;

        if (p->proto == IPPROTO_TCP && i == TMM_STREAMTCP) {
            tmm_streamtcp_tcp = tmm_delta;
        }
    }

    fprintf(packet_profile_csv_fp, "%"PRIu64",", delta - tmm_total);

    uint64_t app_total = 0;
    for (i = 0; i < ALPROTO_MAX; i++) {
        PktProfilingAppData *pdt = &p->profile->app[i];

        fprintf(packet_profile_csv_fp,"%"PRIu64",", pdt->ticks_spent);

        if (p->proto == IPPROTO_TCP) {
            app_total += pdt->ticks_spent;
        }
    }

    uint64_t real_tcp = 0;
    if (tmm_streamtcp_tcp > app_total)
        real_tcp = tmm_streamtcp_tcp - app_total;
    fprintf(packet_profile_csv_fp, "%"PRIu64",", real_tcp);

    fprintf(packet_profile_csv_fp, "%"PRIu64",", p->profile->proto_detect);

    for (i = 0; i < PROF_DETECT_SIZE; i++) {
        PktProfilingDetectData *pdt = &p->profile->detect[i];

        fprintf(packet_profile_csv_fp,"%"PRIu64",", pdt->ticks_spent);
    }
    fprintf(packet_profile_csv_fp,"\n");
}

static void SCProfilingUpdatePacketDetectRecord(PacketProfileDetectId id, uint8_t ipproto, PktProfilingDetectData *pdt, int ipver) {
    if (pdt == NULL) {
        return;
    }

    SCProfilePacketData *pd;
    if (ipver == 4)
        pd = &packet_profile_detect_data4[id][ipproto];
    else
        pd = &packet_profile_detect_data6[id][ipproto];

    if (pd->min == 0 || pdt->ticks_spent < pd->min) {
        pd->min = pdt->ticks_spent;
    }
    if (pd->max < pdt->ticks_spent) {
        pd->max = pdt->ticks_spent;
    }

    pd->tot += pdt->ticks_spent;
    pd->cnt ++;
}

void SCProfilingUpdatePacketDetectRecords(Packet *p) {
    PacketProfileDetectId i;
    for (i = 0; i < PROF_DETECT_SIZE; i++) {
        PktProfilingDetectData *pdt = &p->profile->detect[i];

        if (pdt->ticks_spent > 0) {
            if (PKT_IS_IPV4(p)) {
                SCProfilingUpdatePacketDetectRecord(i, p->proto, pdt, 4);
            } else {
                SCProfilingUpdatePacketDetectRecord(i, p->proto, pdt, 6);
            }
        }
    }
}

static void SCProfilingUpdatePacketAppPdRecord(uint8_t ipproto, uint32_t ticks_spent, int ipver) {
    SCProfilePacketData *pd;
    if (ipver == 4)
        pd = &packet_profile_app_pd_data4[ipproto];
    else
        pd = &packet_profile_app_pd_data6[ipproto];

    if (pd->min == 0 || ticks_spent < pd->min) {
        pd->min = ticks_spent;
    }
    if (pd->max < ticks_spent) {
        pd->max = ticks_spent;
    }

    pd->tot += ticks_spent;
    pd->cnt ++;
}

static void SCProfilingUpdatePacketAppRecord(int alproto, uint8_t ipproto, PktProfilingAppData *pdt, int ipver) {
    if (pdt == NULL) {
        return;
    }

    SCProfilePacketData *pd;
    if (ipver == 4)
        pd = &packet_profile_app_data4[alproto][ipproto];
    else
        pd = &packet_profile_app_data6[alproto][ipproto];

    if (pd->min == 0 || pdt->ticks_spent < pd->min) {
        pd->min = pdt->ticks_spent;
    }
    if (pd->max < pdt->ticks_spent) {
        pd->max = pdt->ticks_spent;
    }

    pd->tot += pdt->ticks_spent;
    pd->cnt ++;
}

void SCProfilingUpdatePacketAppRecords(Packet *p) {
    int i;
    for (i = 0; i < ALPROTO_MAX; i++) {
        PktProfilingAppData *pdt = &p->profile->app[i];

        if (pdt->ticks_spent > 0) {
            if (PKT_IS_IPV4(p)) {
                SCProfilingUpdatePacketAppRecord(i, p->proto, pdt, 4);
            } else {
                SCProfilingUpdatePacketAppRecord(i, p->proto, pdt, 6);
            }
        }
    }

    if (p->profile->proto_detect > 0) {
        if (PKT_IS_IPV4(p)) {
            SCProfilingUpdatePacketAppPdRecord(p->proto, p->profile->proto_detect, 4);
        } else {
            SCProfilingUpdatePacketAppPdRecord(p->proto, p->profile->proto_detect, 6);
        }
    }
}

void SCProfilingUpdatePacketTmmRecord(int module, uint8_t proto, PktProfilingTmmData *pdt, int ipver) {
    if (pdt == NULL) {
        return;
    }

    SCProfilePacketData *pd;
    if (ipver == 4)
        pd = &packet_profile_tmm_data4[module][proto];
    else
        pd = &packet_profile_tmm_data6[module][proto];

    uint32_t delta = (uint32_t)pdt->ticks_end - pdt->ticks_start;
    if (pd->min == 0 || delta < pd->min) {
        pd->min = delta;
    }
    if (pd->max < delta) {
        pd->max = delta;
    }

    pd->tot += (uint64_t)delta;
    pd->cnt ++;

#ifdef PROFILE_LOCKING
    pd->lock += pdt->mutex_lock_cnt;
    pd->ticks += pdt->mutex_lock_wait_ticks;
    pd->contention += pdt->mutex_lock_contention;
    pd->slock += pdt->spin_lock_cnt;
    pd->sticks += pdt->spin_lock_wait_ticks;
    pd->scontention += pdt->spin_lock_contention;
#endif
}

void SCProfilingUpdatePacketTmmRecords(Packet *p) {
    int i;
    for (i = 0; i < TMM_SIZE; i++) {
        PktProfilingTmmData *pdt = &p->profile->tmm[i];

        if (pdt->ticks_start == 0 || pdt->ticks_end == 0 || pdt->ticks_start > pdt->ticks_end) {
            continue;
        }

        if (PKT_IS_IPV4(p)) {
            SCProfilingUpdatePacketTmmRecord(i, p->proto, pdt, 4);
        } else {
            SCProfilingUpdatePacketTmmRecord(i, p->proto, pdt, 6);
        }
    }
}

void SCProfilingAddPacket(Packet *p) {
    if (p == NULL || p->profile == NULL ||
        p->profile->ticks_start == 0 || p->profile->ticks_end == 0 ||
        p->profile->ticks_start > p->profile->ticks_end)
        return;

    pthread_mutex_lock(&packet_profile_lock);
    {

        if (profiling_packets_csv_enabled)
            SCProfilingPrintPacketProfile(p);

        if (PKT_IS_IPV4(p)) {
            SCProfilePacketData *pd = &packet_profile_data4[p->proto];

            uint64_t delta = p->profile->ticks_end - p->profile->ticks_start;
            if (pd->min == 0 || delta < pd->min) {
                pd->min = delta;
            }
            if (pd->max < delta) {
                pd->max = delta;
            }

            pd->tot += delta;
            pd->cnt ++;

            if (IS_TUNNEL_PKT(p)) {
                pd = &packet_profile_data4[256];

                if (pd->min == 0 || delta < pd->min) {
                    pd->min = delta;
                }
                if (pd->max < delta) {
                    pd->max = delta;
                }

                pd->tot += delta;
                pd->cnt ++;
            }

            SCProfilingUpdatePacketTmmRecords(p);
            SCProfilingUpdatePacketAppRecords(p);
            SCProfilingUpdatePacketDetectRecords(p);

        } else if (PKT_IS_IPV6(p)) {
            SCProfilePacketData *pd = &packet_profile_data6[p->proto];

            uint64_t delta = p->profile->ticks_end - p->profile->ticks_start;
            if (pd->min == 0 || delta < pd->min) {
                pd->min = delta;
            }
            if (pd->max < delta) {
                pd->max = delta;
            }

            pd->tot += delta;
            pd->cnt ++;

            if (IS_TUNNEL_PKT(p)) {
                pd = &packet_profile_data6[256];

                if (pd->min == 0 || delta < pd->min) {
                    pd->min = delta;
                }
                if (pd->max < delta) {
                    pd->max = delta;
                }

                pd->tot += delta;
                pd->cnt ++;
            }

            SCProfilingUpdatePacketTmmRecords(p);
            SCProfilingUpdatePacketAppRecords(p);
            SCProfilingUpdatePacketDetectRecords(p);
        }
    }
    pthread_mutex_unlock(&packet_profile_lock);
}

PktProfiling *SCProfilePacketStart(void) {
    uint64_t sample = SC_ATOMIC_ADD(samples, 1);
    if (sample % rate == 0)
        return SCCalloc(1, sizeof(PktProfiling));
    else
        return NULL;
}

/* see if we want to profile rules for this packet */
int SCProfileRuleStart(Packet *p) {
#ifdef PROFILE_LOCKING
    if (p->profile != NULL) {
        p->flags |= PKT_PROFILE;
        return 1;
    }
#else
    uint64_t sample = SC_ATOMIC_ADD(samples, 1);
    if (sample % rate == 0) {
        p->flags |= PKT_PROFILE;
        return 1;
    }
#endif
    return 0;
}

#define CASE_CODE(E)  case E: return #E

/**
 * \brief Maps the PacketProfileDetectId, to its string equivalent
 *
 * \param id PacketProfileDetectId id
 *
 * \retval string equivalent for the PacketProfileDetectId id
 */
const char * PacketProfileDetectIdToString(PacketProfileDetectId id)
{
    switch (id) {
        CASE_CODE (PROF_DETECT_MPM);
        CASE_CODE (PROF_DETECT_MPM_PACKET);
//        CASE_CODE (PROF_DETECT_MPM_PKT_STREAM);
        CASE_CODE (PROF_DETECT_MPM_STREAM);
        CASE_CODE (PROF_DETECT_MPM_URI);
        CASE_CODE (PROF_DETECT_MPM_HCBD);
        CASE_CODE (PROF_DETECT_MPM_HSBD);
        CASE_CODE (PROF_DETECT_MPM_HHD);
        CASE_CODE (PROF_DETECT_MPM_HRHD);
        CASE_CODE (PROF_DETECT_MPM_HMD);
        CASE_CODE (PROF_DETECT_MPM_HCD);
        CASE_CODE (PROF_DETECT_MPM_HRUD);
        CASE_CODE (PROF_DETECT_MPM_HSMD);
        CASE_CODE (PROF_DETECT_MPM_HSCD);
        CASE_CODE (PROF_DETECT_MPM_HUAD);
        CASE_CODE (PROF_DETECT_MPM_DNSQUERY);
        CASE_CODE (PROF_DETECT_IPONLY);
        CASE_CODE (PROF_DETECT_RULES);
        CASE_CODE (PROF_DETECT_PREFILTER);
        CASE_CODE (PROF_DETECT_STATEFUL);
        CASE_CODE (PROF_DETECT_ALERT);
        CASE_CODE (PROF_DETECT_CLEANUP);
        CASE_CODE (PROF_DETECT_GETSGH);
        case PROF_DETECT_MPM_PKT_STREAM:
            return "PROF_DETECT_MPM_PKT_STR";
        default:
            return "UNKNOWN";
    }
}



#ifdef UNITTESTS

static int
ProfilingGenericTicksTest01(void) {
#define TEST_RUNS 1024
    uint64_t ticks_start = 0;
    uint64_t ticks_end = 0;
    void *ptr[TEST_RUNS];
    int i;

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        ptr[i] = SCMalloc(1024);
    }
    ticks_end = UtilCpuGetTicks();
    printf("malloc(1024) %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCFree(ptr[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCFree(1024) %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    SCMutex m[TEST_RUNS];

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCMutexInit(&m[i], NULL);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCMutexInit() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCMutexLock(&m[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCMutexLock() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCMutexUnlock(&m[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCMutexUnlock() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCMutexDestroy(&m[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCMutexDestroy() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    SCSpinlock s[TEST_RUNS];

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCSpinInit(&s[i], 0);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCSpinInit() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCSpinLock(&s[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCSpinLock() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCSpinUnlock(&s[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCSpinUnlock() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SCSpinDestroy(&s[i]);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SCSpinDestroy() %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    SC_ATOMIC_DECL_AND_INIT(unsigned int, test);
    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        (void) SC_ATOMIC_ADD(test,1);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SC_ATOMIC_ADD %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);

    ticks_start = UtilCpuGetTicks();
    for (i = 0; i < TEST_RUNS; i++) {
        SC_ATOMIC_CAS(&test,i,i+1);
    }
    ticks_end = UtilCpuGetTicks();
    printf("SC_ATOMIC_CAS %"PRIu64"\n", (ticks_end - ticks_start)/TEST_RUNS);
    return 1;
}

#endif /* UNITTESTS */

void
SCProfilingRegisterTests(void)
{
#ifdef UNITTESTS
    UtRegisterTest("ProfilingGenericTicksTest01", ProfilingGenericTicksTest01, 1);
#endif /* UNITTESTS */
}

#endif /* PROFILING */