require 'spec_helper'
require "code_quality/cli"

RSpec.describe CodeQuality::CLI do
  before(:each) { ENV["CI"] = "true" }
  subject(:cli) { "exe/code_quality" }

  describe "run cli with options" do
    it "-T" do
      expect { system "#{cli} -T" }.to output(/Generate security audit and code quality report/).to_stdout_from_any_process
    end

    it "--help" do
      expect { system "#{cli} --help" }.to output(/Display the program version/).to_stdout_from_any_process
    end

    it "--version" do
      expect { system "#{cli} --version" }.to output(/#{CodeQuality::VERSION}/).to_stdout_from_any_process
    end
  end

  describe "run audit tasks" do
    # TODO: suppress output from bundler_audit, brakeman and warning from rubocop
    it "run without any options" do
      expect { system("#{cli}") }.to output(/# Code Quality Report/).to_stdout_from_any_process
    end

    it "run sub task without any options" do
      expect { system "#{cli} security_audit:bundler_audit" }.to output(/## bundler audit/).to_stdout_from_any_process
    end

    describe "return exit status" do
      it "return zero exit status if passed" do
        expect { system "#{cli} quality_audit:rubocop" }.to output.to_stdout_from_any_process.and \
          output(/(AUDIT FAILED){0}.*(rubocop_max_offenses){0}/m).to_stderr_from_any_process
        expect($?.exitstatus).to be_zero
      end

      it "return non-zero exit status if failed" do
        expect { system "#{cli} quality_audit:rubocop rubocop_max_offenses=0" }.to output.to_stdout_from_any_process.and \
          output(/(AUDIT FAILED){1}.*(rubocop_max_offenses){1}/m).to_stderr_from_any_process
        expect($?.exitstatus).not_to be_zero
      end
    end
  end
end
