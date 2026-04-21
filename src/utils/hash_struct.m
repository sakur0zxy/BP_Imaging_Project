function hashText = hash_struct(value)
%HASH_STRUCT 为结构体生成稳定哈希。

jsonText = jsonencode(orderfields(value));
digest = java.security.MessageDigest.getInstance('MD5');
digest.update(uint8(jsonText));
rawBytes = typecast(digest.digest(), 'uint8');
hashText = lower(reshape(dec2hex(rawBytes, 2).', 1, []));
end

