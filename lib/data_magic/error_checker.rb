module DataMagic
  module ErrorChecker
    class << self
      def check(params, options, config)
        report_nonexistent_params(params, config) +
          report_nonexistent_operators(params) +
          report_nonexistent_fields(options[:fields], config) +
          report_bad_sort_argument(options) +
          report_bad_range_argument(params) +
          report_wrong_field_type(params, config)
      end

      private

      def report_nonexistent_params(params, config)
        params.keys.reject { |p| config.field_types.key?(p.sub(/__\w+$/, '')) }.
          map { |p| build_error(error: 'parameter_not_found', input: p.sub(/__\w+$/, '')) }
      end

      def report_nonexistent_operators(params)
        params.keys.select { |p| p =~ /__(\w+)$/ && $1 !~ /range|not|ne/i }.
          map do |p|
            (param, op) = p.match(/^(.*)__(\w+)$/).captures
            build_error(error: 'operator_not_found', parameter: param, input: op)
          end
      end

      def report_nonexistent_fields(fields, config)
        if fields && !fields.empty?
          fields.reject { |f| config.field_types.key?(f.to_s) }.
            map { |f| build_error(error: 'field_not_found', input: f.to_s) }
        else
          []
        end
      end

      def report_bad_sort_argument(options)
        []
      end

      def report_bad_range_argument(params)
        ranges = params.select do |p,v|
          p =~ /__range$/ and
            v !~ / ^(\d+(\.\d+)?)? # optional starting number
                   \.\.           # range dots
                   (\d+(\.\d+))?  # optional ending number
                   (,(\d+(\.\d+)?)?\.\.(\d+(\.\d+)?)?)* # and more, with commas
                   $/x
        end
        ranges.map do |p,v|
          param = p.sub("__range",'')
          build_error(error: 'range_format_error', parameter: param, input: v)
        end
      end

      def report_wrong_field_type(params, config)
        []
      end

      def build_error(opts)
        opts[:message] =
          case opts[:error]
          when 'parameter_not_found'
            "The input parameter '#{opts[:input]}' is not known in this dataset."
          when 'field_not_found'
            "The input field '#{opts[:input]}' (in the fields parameter) is not a field in this dataset."
          when 'operator_not_found'
            "The input operator '#{opts[:input]}' (appended to the parameter '#{opts[:parameter]}') is not known or supported. (Known operators: range, ne, not)"
          when 'parameter_type_error'
            "The parameter '#{opts[:parameter]}' expects a value of type #{opts[:expected_type]}, but received '#{opts[:input]}' which is a value of type #{opts[:input_type]}."
          when 'range_format_error'
            "The range '#{opts[:input]}' supplied to parameter '#{opts[:parameter]}' isn't in the correct format."
          end
        opts
      end
    end
  end
end