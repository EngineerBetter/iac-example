import boto3
from boto3 import client

# ruleid:useless-eqeq
x == x

def __eq__(self, other):
    # OK; skip most things that are inside eqs based on what we saw on platform
    return self == self and self == other

def sure(ofcourse):
    return 1 == 1

class A:
    def __eq__(self, other):
        # OK; skip most things that are inside eqs based on what we saw on platform
        return self == self and self == other


assert(x == x)
assert x == x
assert x == x, "of course"
assertTrue(x ==x)
assertFalse(x == x)

# ruleid:useless-eqeq
print(x != x)



# ruleid:hardcoded-token
client("s3", aws_secret_access_key="jWnyxxxxxxxxxxxxxxxxX7ZQxxxxxxxxxxxxxxxx")
