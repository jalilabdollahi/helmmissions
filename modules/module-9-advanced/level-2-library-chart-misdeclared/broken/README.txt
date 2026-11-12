mqlib/            shared helpers from the messaging team (broker settings)
invoice-mailer/   consumer, release name invoice-mailer
receipt-mailer/   consumer, release name receipt-mailer
Both consumers pull mqlib in from charts/ (helm dependency update).
