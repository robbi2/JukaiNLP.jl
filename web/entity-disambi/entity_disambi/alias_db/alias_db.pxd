# -*- coding: utf-8 -*-


cdef class Alias:
    cdef public unicode name
    cdef public unicode title
    cdef public float prior_prob


cdef class AliasDB:
    cdef public _dawg
    cdef public list _titles
