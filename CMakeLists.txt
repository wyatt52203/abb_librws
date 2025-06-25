cmake_minimum_required(VERSION 2.8.12)
project(abb_librws)
include(GNUInstallDirs)
add_compile_options(-std=c++11)

########################
## POCO C++ Libraries ##
########################
# we need at least 1.4.3 because of websocket support

# find_package(Poco 1.4.3 REQUIRED COMPONENTS Net Util Foundation XML) # INITIAL!

find_package(Poco 1.9.2 REQUIRED COMPONENTS Net Util Foundation XML) # TAG_POCO added io


link_directories("/usr/local/lib") # ACTION 1

# link_directories("/usr/local/include/Poco")


message(STATUS "Poco: ${Poco_INCLUDE_DIRS}") # Use to print in terminal some variable for debug
message(FATAL "Stop")

###########
## Build ##
###########
set(SRC_FILES
    src/rws_client.cpp
    src/rws_common.cpp
    src/rws_interface.cpp
    src/rws_poco_client.cpp
    src/rws_rapid.cpp
    src/rws_state_machine_interface.cpp)

include_directories(include ${Poco_INCLUDE_DIRS})


add_library(${PROJECT_NAME} ${SRC_FILES})
target_link_libraries(${PROJECT_NAME} ${Poco_LIBRARIES} PocoNet PocoUtil PocoFoundation) #  ACTION 2


#############
##   Exec  ##
#############
add_executable(start_rapid_program src/executables/start_rapid_program.cpp)
target_link_libraries(start_rapid_program
  ${PROJECT_NAME}
  ${Poco_LIBRARIES}
  PocoNet
  PocoUtil
  PocoFoundation
  PocoNetSSL
  PocoCrypto
)

add_executable(stop_rapid_program src/executables/stop_rapid_program.cpp)
target_link_libraries(stop_rapid_program
  ${PROJECT_NAME}
  ${catkin_LIBRARIES}
  ${Poco_LIBRARIES}
  PocoNet
  PocoUtil
  PocoFoundation
  PocoNetSSL
  PocoCrypto
)

add_executable(load_file src/executables/load_file.cpp)
target_link_libraries(load_file
  ${PROJECT_NAME}
  ${catkin_LIBRARIES}
  ${Poco_LIBRARIES}
  PocoNet
  PocoUtil
  PocoFoundation
  PocoNetSSL
  PocoCrypto
)

add_executable(read_elogs src/executables/read_elogs.cpp)
target_link_libraries(read_elogs
  ${PROJECT_NAME}
  ${catkin_LIBRARIES}
  ${Poco_LIBRARIES}
  PocoNet
  PocoUtil
  PocoFoundation
  PocoNetSSL
  PocoCrypto
)

#############
## Install ##
#############
install(TARGETS ${PROJECT_NAME}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        FILES_MATCHING PATTERN "*.h")

install(TARGETS
    start_rapid_program
    stop_rapid_program
    load_file
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
