# -*- coding: utf-8 -*-


cdef class Document:
    cdef public list words
    cdef public list mentions
    cdef public str tag
    cdef public id
    cdef list _pos_tags


cdef class Mention:
    cdef public int id
    cdef public unicode text
    cdef public unicode entity_title
    cdef public tuple span
    cdef public list candidates
    cdef public unicode predicted_title
