# https://juejin.im/post/5a30fadc6fb9a0450909814c
# [sudo] gem install xcodeproj

keyword = "searchKey"
ProjectConfigureName = "/ProjectName.xcodeproj"

require 'xcodeproj'

def removeRefs(target,group)
	group.files.each do |file|
		if file.real_path.to_s.end_with?(keyword) then
			target.remove_reference(file)
      	end
  	end
end

def addRefs(filePath,target,group)
	file_refs = []
	Dir.foreach(filePath) do |file|
		if file.to_s.end_with?(keyword) then
			pathNeed = File.join(filePath,file)
			# puts pathNeed
			file_ref = group.new_reference(pathNeed)
			file_refs.push(file_ref)
			# target.resources_build_phase.add_file_reference(file_ref, true)
		end
	end
	# add_file_references
	target.add_resources(file_refs)
end

# add new refs with group
def addRefs2Target(filePath,targets,group)
	file_refs = []
	Dir.foreach(filePath) do |file|
		if file.to_s.end_with?(keyword) then
			pathNeed = File.join(filePath,file)
			# puts path
			file_ref = group.new_reference(pathNeed)
			file_refs.push(file_ref)
			# target.resources_build_phase.add_file_reference(file_ref, true)
		end
	end
	# add_file_references
	targets.each do |target|
		target.add_resources(file_refs)
	end
end

# remove from project
def removeOrignalRef(target,groupName,project,targetEnv)
	# find ref group
	prodPath = File.join(groupName, targetEnv)
	prodGroup = project.main_group.find_subpath(prodPath, false)
	prodGroup.files.each do |file|
		if file.real_path.to_s.end_with?(keyword) then
			puts 'Remove Orignal Refs :'
			puts file.real_path.to_s
			# remove from project
			file.remove_from_project
			# target.remove_reference(file)
      	end
  	end
end

# main entrace
def addFiles(projectPath,fileDir,fileName)
	projectBasePath = projectPath
	downloadedPath = File.join(fileDir, fileName)

	# open Xcodeproj
	project_path = File.join(projectBasePath, ProjectConfigureName)
	project = Xcodeproj::Project.open(project_path)
	# create group
	group = project.main_group.find_subpath(desiredPath, true)
	group.set_source_tree('SOURCE_ROOT')

	# clear old refs
	if !group.empty? then
		group.clear()
	end

	# find target and add refs
	targets = []
	project.targets.each do |target|
		case target.name.to_s
			when 'Target1', 'Target2'
				puts 'Release Target:'

				# remove existed refs in group
				removeRefs(target,group)
	  			targets.push(target)	
			when 'TargetTest'
				# do nothing
				puts 'Dev Target:'
			else
				puts 'Other Target:'
		end
		puts target.name.to_s
	end
	# one ref added into multiply targets
	addRefs2Target(downloadedPath,targets,group)
	project.save
end

addFiles(ARGV[0],ARGV[1],ARGV[2])
