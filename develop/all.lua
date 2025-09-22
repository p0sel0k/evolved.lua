require 'develop.samples.systems'

require 'develop.testing.cancel_tests'
require 'develop.testing.locate_tests'
require 'develop.testing.multi_spawn_tests'
require 'develop.testing.name_tests'
require 'develop.testing.requires_fragment_tests'
require 'develop.testing.system_as_query_tests'

require 'develop.benchmarks.multi_clone_bmarks'
require 'develop.benchmarks.multi_spawn_bmarks'
require 'develop.benchmarks.process_bmarks'

require 'develop.untests'

require 'develop.unbench'
require 'develop.usbench'

local basics = require 'develop.basics'

print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.destroy_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.batch_destroy_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.explicit_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.pack_unpack_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.requires_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.unique_fuzz'
