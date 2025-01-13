DELETE FROM classification where user = 'x_consensus';

INSERT INTO classification
(user, record, method, finalized, protocol_phase, classification_phase, classification, comment)
 SELECT 'x_consensus' as user, record, method, false as finalized, 'consensus' as protocol_phase, classification_phase, classification, max(n)
 FROM expert_classification
 GROUP BY classification_phase, record, method
 ORDER BY record, method, classification_phase;

