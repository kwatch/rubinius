class Selector
  ivar_as_index :name => 0, :send_sites => 1

  def name
    @name
  end

  def inspect
    "#<Selector name=#{@name} sites=#{@send_sites.size}>"
  end

  def send_sites
    @send_sites
  end

  def receives
    @send_sites.inject(0) { |acc, ss| acc + ss.hits + ss.misses }
  end
end
