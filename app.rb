require "sinatra"
require "haml"
require "sinatra/reloader" if development?

def deserialize_params(params)
  params.map do |p|
    {
      p[0] => (p[1].split("|") rescue []) # return empty values if filter param is broken
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

  # generate a new query string based on the current state of
  # self and other filters. This method is called for each listed
  # value
  def new_filter_query(filter_name, current_value)
    query = Hash.new

    # If the current filter value is not active,
    # the value for the new query is simply self
    if !@params[filter_name]
      query[filter_name] = current_value
    end

    # For the values currently in the params hash,
    # loop over all of them and merge with the value
    # for the filter tag currently being generated
    @params.each do |key, current_values|
      new_values = []

      # if it is selected it gets removed from the new query
      if current_values.include?(current_value)
        new_values = current_values - [current_value]

      else
        # otherwise we check if the value is defined as part of
        # the filter section we’re currently in. If it is, we merge
        # the currently selected one with the one in the current loop
        is_valid_filter = @filters[key].include?(current_value) rescue false
        if is_valid_filter
          new_values = current_values | [current_value]
        else # if it’s not part of the section there is no merge
          new_values = current_values
        end
      end

      query[key] = new_values
    end

    # generate an actual URL query string
    serialize_params(query)
  end
end

before do
  @params = deserialize_params(params)
  @filters = {
    "color"    => %w(red green purple),
    "material" => %w(wood glass metal stone),
    "style" => %w(classic modern),
    "price" => ["50-100", "100-500"],

  }
end

get '/' do
  redirect '/search', 302
end

get '/search' do
  haml :search
end