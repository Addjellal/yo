# CMake generated Testfile for 
# Source directory: /home/user/yo/simulateur
# Build directory: /home/user/yo/simulateur/build-asan
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(coeur "/home/user/yo/simulateur/build-asan/tests_coeur")
set_tests_properties(coeur PROPERTIES  _BACKTRACE_TRIPLES "/home/user/yo/simulateur/CMakeLists.txt;165;add_test;/home/user/yo/simulateur/CMakeLists.txt;0;")
add_test(schema "/home/user/yo/simulateur/build-asan/tests_schema")
set_tests_properties(schema PROPERTIES  ENVIRONMENT "QT_QPA_PLATFORM=offscreen" _BACKTRACE_TRIPLES "/home/user/yo/simulateur/CMakeLists.txt;252;add_test;/home/user/yo/simulateur/CMakeLists.txt;0;")
