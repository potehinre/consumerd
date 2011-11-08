#!/usr/bin/env python
import pika
import sys
import random

connection = pika.BlockingConnection(pika.ConnectionParameters(host='192.168.1.193'))
channel = connection.channel()

very_huge_string = """ BLZHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                       AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                       AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                       AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD """

message = "info:" + str(random.randint(1,1000)) + very_huge_string
channel.basic_publish(exchange='markers',
                      routing_key='',
                      body = message)
print " [x] Sent %r" % (message,)
connection.close()
