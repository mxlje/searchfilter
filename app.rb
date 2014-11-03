require "sinatra"
require "haml"
require "json"
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
    s = {}
    h.map do |k, v|
      s[k] = Array(v).join("|") unless Array(v).empty?
    end

    s.to_json
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
  @filters = {
    "color"    => %w(red green purple),
    "material" => %w(wood glass metal stone),
    "style" => %w(classic modern),
    "size" => %w(minature small medium large oversize),
    "price" => ["50-100", "100-300", "300-500"],
  }
end

enable :sessions

get '/' do
  redirect '/search', 302
end

get '/search' do
  @params = session[:qs] || {}
  haml :search
end




def parse_json_qs(json)
  query = Hash.new
  qs = JSON.parse(json)
  
  qs.each do |k, v|
    v = v.is_a?(String) ? v.split("|") : ""
    query[k] = v
  end

  query
end

post '/search/filter' do
  querystring = params["qs"].to_s
  # session[:qs] = querystring

  session[:qs] = parse_json_qs(querystring)
  
  redirect '/search', 303
end 

post '/search/clear' do
  session[:qs] = {}
  redirect '/search', 303
end

post '/inspect' do
  params.to_json
end