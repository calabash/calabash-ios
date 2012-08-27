#!/bin/bash
javac -cp target/calabash-jvm-0.0.1-standalone.jar:target/classes example/*.java  -d target/classes && java -cp target/calabash-jvm-0.0.1-standalone.jar:target/classes calabash_jvm.Example


