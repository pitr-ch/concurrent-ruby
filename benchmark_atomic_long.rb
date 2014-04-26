$:.push File.join(File.dirname(__FILE__), 'lib')

require 'concurrent'
require 'benchmark'

def atomic_test(clazz, opts = {})
  threads = opts.fetch(:threads, 5)
  tests = opts.fetch(:tests, 100)

  num = clazz.new
  latch = Concurrent::CountDownLatch.new(threads)

  print "Testing with #{clazz}...\n"
  stats = Benchmark.measure do
    threads.times do |i|
      Thread.new do
        tests.times{ num.up }
        latch.count_down
      end
    end
    latch.wait
  end
  print stats
end

atomic_test(Concurrent::MutexAtomicFixnum, threads: 10, tests: 1_000_000)

if defined? Concurrent::CAtomicFixnum
  atomic_test(Concurrent::CAtomicFixnum, threads: 10, tests: 1_000_000)
elsif RUBY_PLATFORM == 'java'
  atomic_test(Concurrent::JavaAtomicFixnum, threads: 10, tests: 1_000_000)
end

# About This Mac
# OS X Version 10.9.2
# Processor 2.6 GHz Intel Core i5
# Memory 8 GB 1600 MHz DDR3

# ruby 2.1.1p76 (2014-02-24 revision 45161) [x86_64-darwin13.0]
#
# Testing with Concurrent::MutexAtomicFixnum...
#=> 2.770000   0.010000   2.780000 (  2.773536)
#
# Testing with Concurrent::CAtomicFixnum...
# with GCC atomic operations
#=> 0.790000   0.000000   0.790000 (  0.790314)
#
# Testing with Concurrent::CAtomicFixnum...
# with pthread mutex
#=> 1.160000   0.000000   1.160000 (  1.163147)

# jruby 1.7.11 (1.9.3p392) 2014-02-24 86339bb on Java HotSpot(TM) 64-Bit Server VM 1.6.0_65-b14-462-11M4609 [darwin-x86_64]
#
# Testing with Concurrent::MutexAtomicFixnum...
#=> 5.670000   3.290000   8.960000 (  5.373000)
#
# Testing with Concurrent::JavaAtomicFixnum...
#=> 4.280000   0.030000   4.310000 (  1.236000)
