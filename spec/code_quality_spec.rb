require 'spec_helper'
require 'rake'

RSpec.describe CodeQuality do
  it "has a version number" do
    expect(CodeQuality::VERSION).not_to be nil
  end

  def load_rake_tasks
    # Rake.application.rake_require 'tasks/code_quality.rake' # Can't find tasks/code_quality.rake
    Rake::Task.send :load, 'tasks/code_quality.rake'
  end

  def run_rake(task_name, options = {})
    env = {"CI" => "true"}
    if !options[:env].to_s.empty?
      env_options = parse_env(options[:env])
      env.merge!(env_options) if env_options.any?
    end
    wrap_env(env) do
      Rake::Task[task_name].reenable
      Rake::Task[task_name].invoke
    end
  end

  it "load rake task" do
    expect{ Rake::Task['code_quality'] }.to raise_error(RuntimeError) # "Don't know how to build task 'code_quality'"

    load_rake_tasks

    expect{ Rake::Task['code_quality'] }.not_to raise_error
  end

  describe "rake code_quality", type: :task do
    before { Rake::Task.clear; load_rake_tasks }

    # TODO: suppress output from bundler_audit and warning from rubocop
    it "work for ruby project" do
      expect {
        expect { run_rake 'code_quality' }.not_to raise_error
      }.to output(/# Code Quality Report/).to_stdout
    end

    it ":quality_audit:rubycritic" do
      expect { run_rake 'code_quality:quality_audit:rubycritic' }.to output(/## Rubycritic/).to_stdout
    end

    it ":quality_audit:rubocop" do
      expect { run_rake 'code_quality:quality_audit:rubocop' }.to output(/## rubocop/).to_stdout
    end

    it ":quality_audit:metric_fu" do
      expect { run_rake 'code_quality:quality_audit:metric_fu' }.to output(/## metric_fu/).to_stdout
    end

    # Audit task should return non-zero exit status and showing failure reason when passing an audit value option and the value is lower than the result in report
    it "return non-zero exit status if failed" do
      expect { run_rake "code_quality:quality_audit:rubocop", env: "rubocop_max_offenses=0" }.to raise_error(SystemExit).and output.to_stdout.and output(/rubocop_max_offenses/).to_stderr
    end

    context 'security_audit with option' do
      it "bundler_audit_options=" do
        expect {
          run_rake "code_quality:security_audit:bundler_audit"
        }.to output(/No vulnerabilities found/).to_stdout_from_any_process

        expect {
          run_rake "code_quality:security_audit:bundler_audit", env: 'bundler_audit_options="--ignore CVE-2020-5267 CVE-2020-10663"'
        }.to output(/No vulnerabilities found/).to_stdout_from_any_process
      end

      # TODO: capture brakeman output
      it "brakeman_options=" do
        expect {
          run_rake "code_quality:security_audit:brakeman"
        }.to output(/Templates: 1/).to_stdout_from_any_process

        expect {
          run_rake "code_quality:security_audit:brakeman", env: 'brakeman_options="--skip-files app/views/"'
        }.to output(/Templates: 0/).to_stdout_from_any_process
      end
    end

    context 'quality_audit with option' do
      it "fail_fast=false" do
        expect {
          run_rake "code_quality:quality_audit", env: "fail_fast=false rubocop_max_offenses=0 lowest_score=101"
        }.to raise_error(SystemExit).and output.to_stdout.and output(/(lowest_score){1}.*(rubocop_max_offenses){1}/m).to_stderr
      end

      it "fail_fast=true" do
        expect {
          run_rake "code_quality:quality_audit", env: "fail_fast=true rubocop_max_offenses=0 lowest_score=101"
        }.to raise_error(SystemExit).and output.to_stdout.and output(/(lowest_score){1}.*(rubocop_max_offenses){0}/m).to_stderr
      end

      it "generate_index=true" do
        expect {
          run_rake "code_quality:quality_audit", env: "generate_index=true"
        }.to output(/Generate report index to/).to_stdout
      end
    end

  end
end
