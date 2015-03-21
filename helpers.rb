helpers do
  def symbolize_keys(hash)
    return nil if hash.nil?
    hash.inject({}){|result, (key, value)|
      new_key = case key
                when String then key.to_sym
                else key
                end
      new_value = case value
                  when Hash then symbolize_keys(value)
                  else value
                  end
      result[new_key] = new_value
      result
    }
  end

  # TODO: put in service?
  def transformations_to_lambda view_schema
    view_schema.each do |key, data|
      if data.is_a? Hash
        [:UP, :DOWN].each do |dir|
          if (v=data[dir]).is_a?(Hash) && (t=v[:transformer]).is_a?(String)
            data[dir][:transformer] = eval t
          end
        end
      end
    end
  end
end

