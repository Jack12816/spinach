module Spinach
  class Runner
    # A feature runner handles a particular feature run.
    #
    class Feature
      # The {Reporter} used in this feature.
      attr_reader :reporter

      # The file that describes the feature.
      attr_reader :filename

      # @param [String] filename
      #   path to the feature file. Scenario line could be passed to run just
      #   that scenario.
      #   @example feature/a_cool_feature.feature:12
      #
      # @param [Spinach::Reporter] reporter
      #   the reporter that will log this run
      #
      # @api public
      def initialize(filename, reporter)
        @filename, @scenario_line = filename.split(':')
        @reporter = reporter
      end

      # @return [Feature]
      #   The feature object used to run this scenario.
      #
      # @api public
      def feature
        @feature ||= Spinach.find_feature(feature_name).new
      end

      # @return [Hash]
      #   The parsed data for this feature.
      #
      # @api public
      def data
        @data ||= Spinach::Parser.new(filename).parse
      end

      # @return [String]
      #   This feature name.
      #
      # @api public
      def feature_name
        @feature_name ||= data['name']
      end

      # @return [Hash]
      #   The parsed scenarios for this runner's feature.
      #
      # @api public
      def scenarios
        @scenarios ||= (data['elements'] || [])
      end

      # Runs this feature.
      #
      # @return [true, false]
      #   Whether the run was successful or not.
      #
      # @api public
      def run
        reporter.feature(feature_name)
        failures = []

        feature.run_hook :before, feature_name

        scenarios.each do |scenario|
          if !@scenario_line || scenario['line'].to_s == @scenario_line
            failure = Scenario.new(feature_name, feature, scenario, reporter).run
            failures << failure if failure
          end
        end

        feature.run_hook :after, feature_name

        if failures.any?
          reporter.error_summary(failures)
          false
        else
          true
        end
      end
    end
  end
end
