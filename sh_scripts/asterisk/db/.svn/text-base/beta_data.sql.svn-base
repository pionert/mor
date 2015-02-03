# DATA
INSERT INTO codecs (name, long_name, codec_type) SELECT 'g722', 'G.722', 'audio' FROM dual WHERE (SELECT COUNT(*) FROM codecs WHERE name = 'g722') = 0;
UPDATE devices SET auth = 'md5' WHERE device_type = 'IAX2';
