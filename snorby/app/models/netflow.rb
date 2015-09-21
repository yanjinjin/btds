class NetFlow
  include DataMapper::Resource

  property :id, Serial, :required => true, :unique => true , :index => true

  property :decoder_pkts, Integer, :max => 1000000000000, :default => 0
  property :decoder_bytes, Integer, :max => 1000000000000, :default => 0
  property :decoder_ipv4, Integer, :max => 1000000000000, :default => 0
  property :decoder_ipv6, Integer, :max => 1000000000000, :default => 0
  property :decoder_tcp, Integer, :max => 1000000000000, :default => 0
  property :decoder_udp, Integer, :max => 1000000000000, :default => 0
  property :decoder_icmpv4, Integer, :max => 1000000000000, :default => 0
  property :decoder_icmpv6, Integer, :max => 1000000000000, :default => 0
  property :decoder_gre, Integer, :max => 1000000000000, :default => 0
  property :tcp_sessions, Integer, :max => 1000000000000, :default => 0
  property :tcp_syn, Integer, :max => 1000000000000, :default => 0
  property :tcp_rst, Integer, :max => 1000000000000, :default => 0
  property :date, DateTime, :unique => true

  def initialize
    decoder_pkts, decoder_bytes, decoder_ipv4, decoder_ipv6, decoder_tcp, decoder_udp, decoder_icmpv4, decoder_icmpv6, decoder_gre, tcp_sessions, tcp_syn, tcp_rst = 0,0,0,0,0,0,0,0,0,0,0,0
  end

  def self.substract(obj1, obj2)
    if obj1.class == NetFlow && obj2.class == NetFlow
      net_flow = NetFlow.new
      if obj1.date.to_i - obj2.date.to_i > 12
        net_flow.date = obj1.date
        return net_flow
      end
      attr_list = [:decoder_pkts, :decoder_bytes, :decoder_ipv4, :decoder_ipv6, :decoder_tcp, :decoder_udp, :decoder_icmpv4, :decoder_icmpv6, :decoder_gre, :tcp_sessions, :tcp_syn, :tcp_rst]
      attr_list.each do |attr|
        tmp1 = obj1.method(attr).call
        tmp2 = obj2.method(attr).call
        tmp = tmp1 - tmp2
        if tmp < 0
          netflow = NetFlow.new
          break
        else
          net_flow.method(attr.to_s + "=").call tmp
        end
      end
      net_flow.date = obj1.date
      return net_flow
    else
      raise "the type of attrs is wrong"
    end
  end

  def self.query_by_sql(sql)
    return db_select(sql)
  end
end
