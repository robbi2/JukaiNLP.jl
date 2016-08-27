# -*- coding: utf-8 -*-

import pkg_resources
import jnius_config

jnius_config.set_classpath(
    pkg_resources.resource_filename(
        'entity_disambi.utils', '/opennlp/opennlp-tools-1.5.3.jar'
    ),
)

from jnius import autoclass

File = autoclass('java.io.File')
POSModel = autoclass('opennlp.tools.postag.POSModel')
POSTaggerME = autoclass('opennlp.tools.postag.POSTaggerME')
SentenceModel = autoclass('opennlp.tools.sentdetect.SentenceModel')
SentenceDetectorME = autoclass('opennlp.tools.sentdetect.SentenceDetectorME')
TokenizerModel = autoclass('opennlp.tools.tokenize.TokenizerModel')
TokenizerME = autoclass('opennlp.tools.tokenize.TokenizerME')


cdef class OpenNLPPOSTagger:
    cdef _tagger

    def __init__(self):
        token_model_file = pkg_resources.resource_filename(
            __name__, 'opennlp/en-pos-maxent.bin')
        pos_model = POSModel(File(token_model_file))
        self._tagger = POSTaggerME(pos_model)

    cpdef list tag(self, list words):
        return self._tagger.tag([w.encode('utf-8') for w in words])


cdef class OpenNLPTokenizer:
    cdef object _tokenizer
    cdef OpenNLPSentenceDetector _sentence_detector

    def __init__(self):
        token_model_file = pkg_resources.resource_filename(
            __name__, 'opennlp/en-token.bin'
        )
        tokenizer_model = TokenizerModel(File(token_model_file))
        self._tokenizer = TokenizerME(tokenizer_model)
        self._sentence_detector = OpenNLPSentenceDetector()

    cpdef list tokenize(self, unicode text):
        words = []
        for (s_start, s_end) in self._sentence_detector.sent_pos_detect(text):
            for span_ins in self._tokenizer.tokenizePos(text[s_start:s_end]):
                span = (span_ins.getStart() + s_start,
                        span_ins.getEnd() + s_start)
                word = text[span[0]:span[1]]
                words.append(word)

        return words


cdef class OpenNLPSentenceDetector:
    cdef object _detector

    def __init__(self):
        sentence_model_file = pkg_resources.resource_filename(
            __name__, 'opennlp/en-sent.bin'
        )
        sentence_model = SentenceModel(File(sentence_model_file))
        self._detector = SentenceDetectorME(sentence_model)

    cpdef list sent_pos_detect(self, unicode text):
        return [(span.getStart(), span.getEnd())
                for span in self._detector.sentPosDetect(text)]
