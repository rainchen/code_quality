require "rake"

module CodeQuality
  class CLI
    def self.start(argv = ARGV)
      Application.new.run
    end

    # doc: http://www.rubydoc.info/gems/rake/Rake/Application
    class Application < Rake::Application
      def initialize
        super
        @name = "code_quality"
      end

      def run
        Rake.application = self
        @rakefiles = []
        add_import File.join(lib_dir, "tasks", "code_quality.rake")
        standard_exception_handling do
          init name
          load_rakefile
          top_level
        end
      end

      def in_namespace(name)
        if name == @name # remove root namespace
          yield
        else
          super
        end
      end

      # allow option "--help"
      def handle_options
        options.rakelib = ["rakelib"]
        options.trace_output = $stderr

        OptionParser.new do |opts|
          opts.separator "Run code_quality for a ruby/rails project, e.g.:"
          opts.separator "    code_quality lowest_score=90 rubocop_max_offenses=100 metrics=stats,rails_best_practices,roodi rails_best_practices_max_offenses=10 roodi_max_offenses=10"
          opts.separator ""
          opts.separator "Show available tasks:"
          opts.separator "    code_quality -T"
          opts.separator ""
          opts.separator "Invoke an audit task:"
          opts.separator "    code_quality AUDIT_TASK"
          opts.separator ""
          opts.separator "Invoke all security audit tasks:"
          opts.separator "    code_quality security_audit"
          opts.separator ""
          opts.separator "Invoke all quality audit tasks:"
          opts.separator "    code_quality quality_audit"
          opts.separator ""
          opts.separator "Advanced options:"

          opts.on_tail("-h", "--help", "-H", "Display this help message.") do
            puts opts
            exit
          end

          standard_rake_options.each { |args| opts.on(*args) }
          opts.environment("RAKEOPT")
        end.parse!
      end

      # overwrite options
      def sort_options(options)
        super.push(__version)
      end

      # allow option "--version"
      def __version
        ["--version", "-V",
         "Display the program version.",
         lambda do |_value|
           puts "CodeQuality #{CodeQuality::VERSION}"
           exit
         end]
      end

      # allows running `code_quality` without a Rakefile
      def find_rakefile_location
        if (location = super).nil?
          [rakefile_path, Dir.pwd]
        else
          location
        end
      end

      def lib_dir
        File.expand_path("../../../lib", __FILE__)
      end

      def rakefile_path
        File.join(lib_dir, "code_quality.rb")
      end
    end
  end
end
