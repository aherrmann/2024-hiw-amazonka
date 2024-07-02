{ bundlerEnv, ruby_3_0 }:

bundlerEnv {
  name = "deal-web-backend-gems";
  ruby = ruby_3_0;
  gemdir = ./gems;
}
