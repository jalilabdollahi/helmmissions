# Find The Last Good Revision - Walkthrough

1. Current symptom:
   ```bash
   kubectl run -n helmissions curl --rm -it --restart=Never --image=curlimages/curl:8.10.1 -- curl -s freight-quote/quote
   # {"rate":0,"insurance":true,"currency":"EUR"}
   helm history freight-quote -n helmissions     # six revisions, no hint which is good
   ```
2. Inspect each revision's inputs:
   ```bash
   for r in 1 2 3 4 5 6; do echo "rev $r"; helm get values freight-quote -n helmissions --revision $r; done
   ```
   | rev | values | verdict |
   |-----|--------|---------|
   | 1 | insurance=false | works, but no insurance quotes |
   | 2 | image.tag=1.27-alpin3 | image never pulls |
   | 3 | gzip=maybe | nginx rejects the config and crashes |
   | 4 | insurance=true | healthy and correct |
   | 5 | readyPath=/ready | pods never become Ready |
   | 6 | rate=0 | healthy, wrong rate |
3. Roll back to revision 4:
   ```bash
   helm rollback freight-quote 4 -n helmissions --wait
   helm history freight-quote -n helmissions     # 7  deployed  Rollback to 4
   ```
4. Verify `/quote` returns `"rate":42` and `"insurance":true`, then run `check`.
