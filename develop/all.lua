require 'develop.example'
require 'develop.unbench'
require 'develop.untests'
require 'develop.usbench'

local basics = require 'develop.basics'

print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.destroy_fuzz'
print '----------------------------------------'
basics.describe_fuzz 'develop.fuzzing.batch_destroy_fuzz'
