

##File source: https://github.com/ethereum/cpp-dependencies/blob/master/jsonrpc.cmake


# HTTP client from JSON RPC CPP requires curl library. It can find it itself,
# but we need to know the libcurl location for static linking.
find_package(CURL REQUIRED)

# HTTP server from JSON RPC CPP requires microhttpd library. It can find it itself,
# but we need to know the MHD location for static linking.
find_package(MHD REQUIRED)

include(${CMAKE_ROOT}/Modules/ExternalProject.cmake)

set(CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
               -DCMAKE_BUILD_TYPE=Release
               # Build static lib but suitable to be included in a shared lib.
               -DCMAKE_POSITION_INDEPENDENT_CODE=On
               -DBUILD_STATIC_LIBS=On
               -DBUILD_SHARED_LIBS=Off
               -DUNIX_DOMAIN_SOCKET_SERVER=Off
               -DUNIX_DOMAIN_SOCKET_CLIENT=Off
               -DHTTP_SERVER=On
               -DHTTP_CLIENT=On
               -DCOMPILE_TESTS=Off
               -DTCP_SOCKET_SERVER=On
               -DCOMPILE_STUBGEN=Off
               -DCOMPILE_EXAMPLES=Off
               # Point to jsoncpp library.
               -DJSONCPP_INCLUDE_DIR=${JSONCPP_INCLUDE_DIRS}
               # Select jsoncpp include prefix: <json/...> or <jsoncpp/json/...>
               -DJSONCPP_INCLUDE_PREFIX=${JSON_PREFIX}
               -DJSONCPP_LIBRARY=${JSONCPP_LIBRARY_DIRS}
               -DCURL_INCLUDE_DIR=${CURL_INCLUDE_DIR}
               -DCURL_LIBRARY=${CURL_LIBRARY}
               -DMHD_INCLUDE_DIR=${MHD_INCLUDE_DIR}
               -DMHD_LIBRARY=${MHD_LIBRARY})

ExternalProject_Add(jsonrpc-project
    PREFIX src/depends/jsonrpc
    URL https://github.com/cinemast/libjson-rpc-cpp/archive/v0.7.0.tar.gz
    URL_HASH SHA256=669c2259909f11a8c196923a910f9a16a8225ecc14e6c30e2bcb712bab9097eb
    # On Windows it tries to install this dir. Create it to prevent failure.
    PATCH_COMMAND cmake -E make_directory <SOURCE_DIR>/win32-deps/include
    CMAKE_ARGS ${CMAKE_ARGS}
    # Overwtire build and install commands to force Release build on MSVC.
    BUILD_COMMAND cmake --build <BINARY_DIR> --config Release
    INSTALL_COMMAND cmake --build <BINARY_DIR> --config Release --target install
)



# Create jsonrpc imported libraries
if (WIN32)
    # On Windows CMAKE_INSTALL_PREFIX is ignored and installs to dist dir.
    ExternalProject_Get_Property(jsonrpc-project BINARY_DIR)
    set(INSTALL_DIR ${BINARY_DIR}/dist)
else()
    ExternalProject_Get_Property(jsonrpc-project INSTALL_DIR)
endif()

set(JSONRPC_INCLUDE_DIR ${INSTALL_DIR}/include)
set(JSONRPC_LIBRARIES ${INSTALL_DIR}/lib)
file(MAKE_DIRECTORY ${JSONRPC_INCLUDE_DIR})  # Must exist.

add_library(jsonrpc::common STATIC IMPORTED)
set_property(TARGET jsonrpc::common PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-common${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET jsonrpc::common PROPERTY INTERFACE_LINK_LIBRARIES ${JSONCPP_LINK_TARGETS})
set_property(TARGET jsonrpc::common PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${JSONRPC_INCLUDE_DIR} ${JSONCPP_INCLUDE_DIR})
add_dependencies(jsonrpc::common jsonrpc-project)

add_library(jsonrpc::client STATIC IMPORTED)
set_property(TARGET jsonrpc::client PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-client${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET jsonrpc::client PROPERTY INTERFACE_LINK_LIBRARIES jsonrpc::common ${CURL_LIBRARY})
set_property(TARGET jsonrpc::client PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIR})
add_dependencies(jsonrpc::client jsonrpc-project)

add_library(jsonrpc::server STATIC IMPORTED)
set_property(TARGET jsonrpc::server PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-server${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET jsonrpc::server PROPERTY INTERFACE_LINK_LIBRARIES jsonrpc::common ${MHD_LIBRARY})
set_property(TARGET jsonrpc::server PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${MHD_INCLUDE_DIR})
add_dependencies(jsonrpc::server jsonrpc-project)


unset(INSTALL_DIR)
unset(CMAKE_ARGS)
