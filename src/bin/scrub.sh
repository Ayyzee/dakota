#!/bin/bash

set -o nounset -o errexit -o pipefail

bin/scrub.pl < dakota.dk > /tmp/dakota.dk
diff dakota.dk /tmp/dakota.dk || /usr/bin/true
wc dakota.dk /tmp/dakota.dk
