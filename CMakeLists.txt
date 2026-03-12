cmake_minimum_required(VERSION 3.16)

project(LZ_VKS VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appLZ_VKS
    main.cpp
)

# Copy the JSON config next to the executable at configure time
configure_file(products.json ${CMAKE_CURRENT_BINARY_DIR}/products.json COPYONLY)

qt_add_qml_module(appLZ_VKS
    URI LZ_VKS
    VERSION 1.0
    QML_FILES
        Main.qml
    SOURCES
        productconfig.h
        productconfig.cpp
)

set_target_properties(appLZ_VKS PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appLZ_VKS
    PRIVATE Qt6::Quick Qt6::Core
)

include(GNUInstallDirs)
install(TARGETS appLZ_VKS
    BUNDLE  DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
