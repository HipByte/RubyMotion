test_begin "test_attr"

# assert_equal 'ok', proc{
#   module M
#     class A
#       class << self
#         attr_accessor :at
#         def workflow_rule
#           yield self
#         end

#         def eval_str(str)
#           eval(str)
#         end
#       end
#     end
#   end
#   begin
#     M::A.eval_str(<<-END)
#     workflow_rule do |r|
#       r.at 1
#     end
#     END
#   rescue ArgumentError => e
#     "ok"
#   end
# }, '[ruby-core:14641]'

# assert_equal %{ok}, proc{
#   class A
#     attr :m
#   end
#   begin
#     A.new.m(3)
#   rescue ArgumentError => e
#     "ok"
#   end
# }, '[ruby-core:15120]'

test_end
