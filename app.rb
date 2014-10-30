require "sinatra"
require "haml"
require "sinatra/reloader" if development?

def deserialize_params(params)
  params.map do |p|
    {
      p[0] => p[1].split("|")
    }
  end.reduce(Hash.new, :merge)
end

helpers do
  def serialize_params(h)
    p = h.map do |k, v|
      "#{k}=#{Array(v).join("|")}" unless Array(v).empty?
    end.compact.join("&").prepend("?")

    p == "?" ? "" : p
  end

  def new_filter_query(filter_name, current_value)
    # check if the filter is currently requested 
    final = {}

    if !@params[filter_name]
      final[filter_name] = current_value
    end

    @params.each do |key, current_values|
      new_values = []

      if current_values.include?(current_value)
        new_values = current_values - [current_value]
      else
        if @filters[key].include?(current_value)
          new_values = current_values | [current_value]
        else
          new_values = current_values
        end
      end

      final[key] = new_values
    end

    serialize_params(final)
  end
end

before do
  @params = deserialize_params(params)
  @filters = {
    "color"    => %w(red green purple),
    "material" => %w(wood glass metal stone),
    "style" => %w(classic modern),
    "price" => ["50-100", "100-500"]
  }
end

get '/' do
  redirect '/search', 302
end

get '/search' do
  haml :search
end