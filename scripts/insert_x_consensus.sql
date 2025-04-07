-- This script is no longer used, because x_consensus was obsoleted
DELETE FROM classification
WHERE user = 'x_consensus';

INSERT INTO classification (
                           user,
                           record,
                           method,
                           finalized,
                           protocol_phase,
                           classification_phase,
                           classification,
                           comment
                           )
                           SELECT 'x_consensus' AS user,
                                  record,
                                  method,
                                  1 AS finalized,
                                  'consensus' AS protocol_phase,
                                  classification_phase,
                                  classification,
                                  max(n) 
                           FROM expert_classification
                           GROUP BY classification_phase,
                                    record,
                                    method
                           ORDER BY record,
                                    method,
                                    classification_phase;
