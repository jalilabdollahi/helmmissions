booking/   the booking API chart
The platform team publishes seat-cache as an OCI artifact in the internal registry:
  oci://localhost:5001/m6-oci-dependency-url/charts/seat-cache   (version 2.0.1)
The registry speaks plain HTTP, so helm commands that talk to it need --plain-http.
