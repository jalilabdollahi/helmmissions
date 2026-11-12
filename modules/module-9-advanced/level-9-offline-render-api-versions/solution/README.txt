checkout/        the chart
env/prod.yaml    prod values
render.sh        CI step: helm template -> rendered/prod.yaml   (no cluster access on the runner)
rendered/        committed render output; the deploy step runs:  kubectl apply -f rendered/prod.yaml
