# frozen_string_literal: true

require 'ashttp'
require 'uri'
require 'json'
require 'digest'
require 'rspec'
require 'rspec/retry'
require 'test_utils'
require 'config/config-distribution'
require 'securerandom'
require 'nokogiri'

require_relative '../../indexer/app/lib/realtime_indexer'
require_relative '../../indexer/app/lib/periodic_indexer'
require_relative '../../indexer/app/lib/pui_indexer'

require_relative '../../common/selenium/backend_client_mixin'
module BackendClientMethods
  alias run_all_indexers_orig run_all_indexers
  # patch this to also run our PUI indexer.
  def run_all_indexers
    run_all_indexers_orig
    $pui.run_index_round
  end
end

if ENV['COVERAGE_REPORTS'] == 'true'
  require 'aspace_coverage'
  ASpaceCoverage.start('frontend:test', 'rails')
end

# This defines how we startup the Backend and Solr. It's called by rspec in the
# before(:suite) block
$server_pids = []
$backend_port = TestUtils.free_port_from(3636)
$frontend_port = TestUtils.free_port_from(4545)
$solr_port = TestUtils.free_port_from(2989)
$backend = "http://localhost:#{$backend_port}"
$frontend = "http://localhost:#{$frontend_port}"
$expire = 30_000

AppConfig[:backend_url] = $backend
AppConfig[:solr_url] = "http://localhost:#{$solr_port}"

$backend_start_fn = proc {
  # for the indexers
  TestUtils.start_backend($backend_port,
                          solr_port: $solr_port,
                          session_expire_after_seconds: $expire,
                          realtime_index_backlog_ms: 600_000)
}

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
include FactoryBot::Syntax::Methods

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  #   # This allows you to limit a spec run to individual examples or groups
  #   # you care about by tagging them with `:focus` metadata. When nothing
  #   # is tagged with `:focus`, all examples get run. RSpec also provides
  #   # aliases for `it`, `describe`, and `context` that include `:focus`
  #   # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  #   config.filter_run_when_matching :focus
  #
  #   # Allows RSpec to persist some state between runs in order to support
  #   # the `--only-failures` and `--next-failure` CLI options. We recommend
  #   # you configure your source control system to ignore this file.
  #   config.example_status_persistence_file_path = "spec/examples.txt"
  #
  #   # Limits the available syntax to the non-monkey patched syntax that is
  #   # recommended. For more details, see:
  #   #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  #   config.disable_monkey_patching!
  #
  #   # Many RSpec users commonly either run the entire suite or an individual
  #   # file, and it's useful to allow more verbose output when running an
  #   # individual spec file.
  #   if config.files_to_run.one?
  #     # Use the documentation formatter for detailed output,
  #     # unless a formatter has already been configured
  #     # (e.g. via a command-line flag).
  #     config.default_formatter = "doc"
  #   end
  #
  #   # Print the 10 slowest examples and example groups at the
  #   # end of the spec run, to help surface which specs are running
  #   # particularly slow.
  #   config.profile_examples = 10
  #
  #   # Run specs in random order to surface order dependencies. If you find an
  #   # order dependency and want to debug it, you can fix the order by providing
  #   # the seed, which is printed after each run.
  #   #     --seed 1234
  #   config.order = :random
  #
  #   # Seed global randomization in this process using the `--seed` CLI option.
  #   # Setting this allows you to use `--seed` to deterministically reproduce
  #   # test failures related to randomization by passing the same `--seed` value
  #   # as the one that triggered the failure.
  #   Kernel.srand config.seed

  config.include FactoryBot::Syntax::Methods
  config.include BackendClientMethods

  # show retry status in spec process
  config.verbose_retry = true
  # Try thrice (retry twice)
  config.default_retry_count = 3

  # [:controller, :view, :request].each do |type|
  #   config.include ::Rails::Controller::Testing::TestProcess, :type => type
  #   config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
  #   config.include ::Rails::Controller::Testing::Integration, :type => type
  # end

  config.before(:suite) do
    puts "Starting backend using #{$backend}"
    $server_pids << $backend_start_fn.call
    $admin = BackendClientMethods::ASpaceUser.new('admin', 'admin')
    unless ENV['ASPACE_INDEXER_URL']
      $indexer = RealtimeIndexer.new($backend, nil)
      $period = PeriodicIndexer.new($backend, nil, 'periodic_indexer', false)
      $pui = PUIIndexer.new($backend, nil, 'pui_periodic_indexer')
    end
    FactoryBot.reload
  end

  config.after(:suite) do
    $server_pids.each do |pid|
      TestUtils.kill(pid)
    end
    # For some reason we have to manually shutdown mizuno for the test suite to
    # quit.
    Rack::Handler.get('mizuno').instance_variable_get(:@server) ? Rack::Handler.get('mizuno').instance_variable_get(:@server).stop : next
  end
end

require 'jsonmodel'
require 'client_enum_source'
JSONModel.init(client_mode: false, strict_mode: false, enum_source: ClientEnumSource.new)
include JSONModel
