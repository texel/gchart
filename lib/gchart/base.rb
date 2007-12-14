require "open-uri"
require "uri"

module GChart
  class Base
    attr_accessor :data
    attr_accessor :extras
    attr_accessor :title
    attr_accessor :colors
    attr_accessor :legend
    attr_accessor :max

    attr_reader :width    
    attr_reader :height

    def initialize(options={}, &block)
      @data = []
      @extras = {}
      @width = 300
      @height = 200
  
      options.each { |k, v| send("#{k}=", v) }
      yield(self) if block_given?
    end

    # Sets the chart's width, in pixels. Raises +ArgumentError+ if +width+ is less than 1.
    def width=(width)
      raise ArgumentError, "Invalid width: #{width.inspect}" if width.nil? || width < 1
      @width = width
    end

    # Sets the chart's height, in pixels. Raises +ArgumentError+ if +height+ is less than 1.
    def height=(height)
      raise ArgumentError, "Invalid height: #{height.inspect}" if height.nil? || height < 1
      @height = height
    end

    # Returns the chart's size as "WIDTHxHEIGHT".
    def size
      "#{width}x#{height}"
    end

    # Sets the chart's size as "WIDTHxHEIGHT".
    def size=(size)
      self.width, self.height = size.split("x").collect { |n| Integer(n) }
    end

    # Returns the chart's URL.
    def to_url
      query = query_params.collect { |k, v| "#{k}=#{URI.escape(v)}" }.join("&")
      "#{GChart::URL}?#{query}"
    end

    # Returns the chart's generated PNG as a blob.
    def fetch
      open(to_url) { |io| io.read }
    end

    # Writes the chart's generated PNG to a file. If +io_or_file+ quacks like an IO,
    # +write+ will be called on it instead.
    def write(io_or_file="chart.png")
      return io_or_file.write(fetch) if io_or_file.respond_to?(:write)
      open(io_or_file, "w+") { |io| io.write(fetch) }
    end

    protected
    
    def query_params
      params = { "cht" => render_chart_type, "chs" => size }
    
      render_data(params)
      render_title(params)
      render_colors(params)
      render_legend(params)

      params.merge(extras)
    end

    def render_chart_type
      raise NotImplementedError, "override in subclasses"
    end
    
    def render_data(params)
      raw = data && data.first.is_a?(Array) ? data : [data]
      max = self.max || raw.collect { |s| s.max }.max
  
      sets = raw.collect do |set|
        set.collect { |n| GChart.encode(:extended, n, max) }.join
      end
  
      params["chd"] = "e:#{sets.join(",")}"
    end
    
    def render_title(params)
      params["chtt"] = title.tr("\n", "|").gsub(/\s+/, "+") if title
    end
    
    def render_colors(params)
      params["chco"] = colors.join(",") if colors  
    end
    
    def render_legend(params)
      params["chl"] = legend.join("|") if legend
    end    
  end
end
