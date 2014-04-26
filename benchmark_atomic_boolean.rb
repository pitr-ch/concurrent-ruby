$:.push File.join(File.dirname(__FILE__), 'lib')

require 'concurrent'
require 'benchmark'

def atomic_test(clazz, opts = {})
  threads = opts.fetch(:threads, 5)
  tests = opts.fetch(:tests, 100)

  atomic = clazz.new
  latch = Concurrent::CountDownLatch.new(threads)

  print "Testing with #{clazz}...\n"
  stats = Benchmark.measure do
    threads.times do |i|
      Thread.new do
        tests.times{ atomic.value = true }
        latch.count_down
      end
    end
    latch.wait
  end
  print stats
end

atomic_test(Concurrent::MutexAtomicBoolean, threads: 10, tests: 1_000_000)

if defined? Concurrent::CAtomicBoolean
  atomic_test(Concurrent::CAtomicBoolean, threads: 10, tests: 1_000_000)
elsif RUBY_PLATFORM == 'java'
  atomic_test(Concurrent::JavaAtomicBoolean, threads: 10, tests: 1_000_000)
end

# About This Mac
# OS X Version 10.9.2
# Processor 2.6 GHz Intel Core i5
# Memory 8 GB 1600 MHz DDR3

# ruby 2.1.1p76 (2014-02-24 revision 45161) [x86_64-darwin13.0]
#
# Testing with Concurrent::MutexAtomicBoolean...
#=> 2.910000   0.010000   2.920000 (  2.913788)
#
# Testing with Concurrent::CAtomicBoolean...
# with GCC atomic operations
#=> 0.840000   0.000000   0.840000 (  0.847371)
#
# Testing with Concurrent::CAtomicBoolean...
# with pthread mutex
#=> 1.190000   0.000000   1.190000 (  1.190992)

# jruby 1.7.11 (1.9.3p392) 2014-02-24 86339bb on Java HotSpot(TM) 64-Bit Server VM 1.6.0_65-b14-462-11M4609 [darwin-x86_64]
#
# Testing with Concurrent::MutexAtomicBoolean...
#=> 5.230000   3.150000   8.380000 (  5.024000)
#
# Testing with Concurrent::JavaAtomicBoolean...
#=> 3.350000   0.020000   3.370000 (  0.903000)
