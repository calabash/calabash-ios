#!/bin/bash
lein clean
lein uberjar

javac -cp target/calabash-jvm-0.0.1-standalone.jar:target/classes example/Example.java  -d target/classes

java -cp target/calabash-jvm-0.0.1-standalone.jar:target/classes Example
