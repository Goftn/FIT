<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
	<div class="container-fluid">
		<div class="navbar-header">
			<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</button>
			<a class="navbar-brand" href="./">Hotel IIS</a>
		</div>
        <div class="navbar-collapse collapse">
			<ul class="nav navbar-nav navbar-right">
				<li><a href="client.php">P�ihl�en: <?php echo $_SESSION['username'] ?></a></li>
				<li><a href="../logout.php">Odhl�sit se</a></li>
			</ul>
        </div>
	</div>
</div>