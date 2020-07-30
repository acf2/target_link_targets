define_property(TARGET PROPERTY TRANSITIVE_SOURCES
                BRIEF_DOCS "Transitive sources for object libs"
                FULL_DOCS "A special property, which sole function is to
                assist propagation of transitive sources of object libraries,
                with use of target_link_targets macro")

macro(target_link_targets NAME)
    # When adding new dependencies, there are two different approaches
    get_target_property(__OBJSTRUCT__NAME_TYPE ${NAME} TYPE)
    if (${__OBJSTRUCT__NAME_TYPE} STREQUAL "OBJECT_LIBRARY")
        # NAME is an object library
        # Links are propagated "as is"
        # Sources, however, should be saved in a shallow list (to iterate over without recursion)
        target_link_libraries(${NAME} ${ARGN})
        foreach(DEPENDENCY ${ARGN})
            if(TARGET ${DEPENDENCY})
                get_target_property(__OBJSTRUCT__DEPENDENCY_TYPE ${DEPENDENCY} TYPE)
                if (${__OBJSTRUCT__DEPENDENCY_TYPE} STREQUAL "OBJECT_LIBRARY")
                    # We forcefully "flatten" sources and public headers
                    set_property(TARGET ${NAME} APPEND
                                 PROPERTY TRANSITIVE_SOURCES
                                 "$<TARGET_OBJECTS:${DEPENDENCY}>;$<GENEX_EVAL:$<TARGET_PROPERTY:${DEPENDENCY},TRANSITIVE_SOURCES>>")
                    set_property(TARGET ${NAME} APPEND
                                 PROPERTY PUBLIC_HEADER
                                 $<GENEX_EVAL:$<TARGET_PROPERTY:${DEPENDENCY},PUBLIC_HEADER>>)
                endif()
            endif()
        endforeach()
    else()
        # NAME is a normal library or executable
        # it is considered a "terminal target"
        # That is, all dependencies from object targets consolidate here
        set(__OBJSTRUCT__ARG_LIST "")
        set(__OBJSTRUCT__SOURCE_LIST "")
        set(__OBJSTRUCT__PUBLIC_HEADER_LIST "")

        foreach(DEPENDENCY ${ARGN})
            if(TARGET ${DEPENDENCY})
                get_target_property(__OBJSTRUCT__DEPENDENCY_TYPE ${DEPENDENCY} TYPE)
                if(${__OBJSTRUCT__DEPENDENCY_TYPE} STREQUAL "OBJECT_LIBRARY")
                    # If a library dependency is an object library, then we should
                    # manually propagate it's transitive source dependencies (not interface ones!)
                    list(APPEND __OBJSTRUCT__ARG_LIST
                         $<GENEX_EVAL:$<TARGET_PROPERTY:${DEPENDENCY},INTERFACE_LINK_LIBRARIES>>)
                    list(APPEND __OBJSTRUCT__PUBLIC_HEADER_LIST
                         $<TARGET_PROPERTY:${DEPENDENCY},PUBLIC_HEADER>)
                    list(APPEND __OBJSTRUCT__SOURCE_LIST
                         "$<TARGET_OBJECTS:${DEPENDENCY}>;$<TARGET_PROPERTY:${DEPENDENCY},TRANSITIVE_SOURCES>")
                else()
                    # For normal dependency everything is "normal", of course
                    list(APPEND __OBJSTRUCT__ARG_LIST ${DEPENDENCY})
                endif()
            endif()
        endforeach()
        # Interfaces are linked "as is"
        target_link_libraries(${NAME} ${__OBJSTRUCT__ARG_LIST})
        # All object files must be checked for duplicates
        target_sources(${NAME} PUBLIC $<REMOVE_DUPLICATES:$<GENEX_EVAL:${__OBJSTRUCT__SOURCE_LIST}>>)
        # And public headers are checked too, just in case
        set_target_properties(${NAME} PROPERTIES
                              PUBLIC_HEADER $<REMOVE_DUPLICATES:$<GENEX_EVAL:${__OBJSTRUCT__PUBLIC_HEADER_LIST}>>)

        unset(__OBJSTRUCT__ARG_LIST)
        unset(__OBJSTRUCT__SOURCE_LIST)
        unset(__OBJSTRUCT__PUBLIC_HEADER_LIST)
    endif()
endmacro()
