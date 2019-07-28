SHADOW_OUT ?= bin/shadow
SHADOW_SRC ?= src/shadow.cr
SYSTEM_BIN ?= /usr/local/bin

install: build
	cp $(SHADOW_OUT) $(SYSTEM_BIN) && rm -f $(SHADOW_OUT)*
build: shard
	crystal build $(SHADOW_SRC) -o $(SHADOW_OUT) --release
test: shard
	crystal spec
shard:
	shards build
clean:
	rm -f $(SHADOW_OUT)* && rm -rf lib && rm -f shard.lock