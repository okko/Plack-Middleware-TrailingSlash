use strict;
use warnings;
 
use Test::More;
 
eval "use Test::Perl::Critic ( -severity => 4, -format => '%m in %f, line %l.' );";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
