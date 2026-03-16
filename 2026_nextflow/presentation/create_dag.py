import graphviz

graph = graphviz.Digraph('DAG', strict=False)

graph.node(str(1), label='Raw data \n(sample 1)', fillcolor='#46a2b3', style='filled')
graph.node(str(2), label='Raw data \n(sample 2)', fillcolor='#46a2b3', style='filled')

graph.node(str(3), label='QC metrics \n(sample 1)', fillcolor='#daf1f5', style='filled')
graph.node(str(4), label='QC metrics \n(sample 2)', fillcolor='#daf1f5', style='filled')

graph.node(str(5), label='Alligned data \n(sample 1)', fillcolor='#daf1f5', style='filled')
graph.node(str(6), label='Alligned data \n(sample 2)', fillcolor='#daf1f5', style='filled')

graph.node(str(7), label='Count matrix \n (aggregated)', fillcolor='#daf1f5', style='filled')

graph.node(str(8), label='DE analysis, \nPCA, plots...', fillcolor='#daf1f5', style='filled')

graph.edge("1", "3", color='black', dir='forward')
graph.edge("2", "4", color='black', dir='forward')

graph.edge("1", "5", color='black', dir='forward')
graph.edge("2", "6", color='black', dir='forward')

graph.edge("5", "7", color='black', dir='forward')
graph.edge("6", "7", color='black', dir='forward')

graph.edge("7", "8", color='black', dir='forward')

graph.render("./figures/pipeline_dag", format="png", cleanup=True)
