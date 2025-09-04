require 'yaml'
require 'fileutils'
require 'open3'
require_relative '../vendor/rouge/lib/rouge'

class OllamaWrapper
  DEFAULT_PROMPTS_FILE = File.expand_path("default_prompts.yml", File.dirname(__FILE__))
  
  # Common model context limits (approximate tokens)
  MODEL_CONTEXT_LIMITS = {
    'llama2' => 4096,
    'llama2:7b' => 4096,
    'llama2:13b' => 4096,
    'llama2:70b' => 4096,
    'llama3' => 8192,
    'llama3:8b' => 8192,
    'llama3:70b' => 8192,
    'llama3.1' => 128000,
    'llama3.1:8b' => 128000,
    'llama3.1:70b' => 128000,
    'llama3.1:405b' => 128000,
    'llama3.2' => 128000,
    'llama3.2:1b' => 128000,
    'llama3.2:3b' => 128000,
    'codellama' => 16384,
    'codellama:7b' => 16384,
    'codellama:13b' => 16384,
    'codellama:34b' => 16384,
    'mistral' => 8192,
    'mistral:7b' => 8192,
    'mixtral' => 32768,
    'mixtral:8x7b' => 32768,
    'qwen' => 8192,
    'qwen:7b' => 8192,
    'qwen:14b' => 8192,
    'qwen:72b' => 8192,
    'gpt-oss:20b' => 8192,  # Conservative estimate
    'gemma' => 8192,
    'gemma:2b' => 8192,
    'gemma:7b' => 8192,
    'phi3' => 4096,
    'phi3:mini' => 4096,
    'yi' => 4096,
    # Claude models
    'claude-3-haiku-20240307' => 200000,
    'claude-3-sonnet-20240229' => 200000,
    'claude-3-opus-20240229' => 200000,
    'claude-3-5-sonnet-20240620' => 200000,
    'claude-3-5-sonnet-20241022' => 200000,
    'claude-3-5-haiku-20241022' => 200000,
    'claude' => 200000,  # Generic claude alias
    'default' => 4096  # Fallback
  }.freeze
  
  def initialize
    @prompts = load_default_prompts
  end
  
  def run(alias_name, *args)
    prompt_config = @prompts[alias_name]
    unless prompt_config
      puts "Error: No prompt found for alias '#{alias_name}'"
      puts "Available aliases: #{@prompts.keys.join(', ')}"
      return false
    end
    
    model = prompt_config['model']
    prompt = prompt_config['prompt']
    
    # Replace any command substitutions in the prompt
    expanded_prompt = expand_command_substitutions(prompt)
    
    # Add any additional arguments to the prompt
    if args.any?
      expanded_prompt += "\n\n" + args.join(" ")
    end
    
    # Check prompt size before calling ollama
    if prompt_too_large?(model, expanded_prompt)
      return false
    end
    
    # Route to appropriate command based on model
    if claude_model?(model)
      call_claude(model, expanded_prompt)
    else
      call_ollama(model, expanded_prompt)
    end
  end
  
  def list_aliases
    puts "Available prompt aliases:"
    @prompts.each do |name, config|
      puts "  #{name}: #{config['model']} - #{config['description'] || 'No description'}"
    end
  end
  
  
  private

  def highlight_markdown(text)
    formatter = Rouge::Formatters::Terminal256.new
    lexer = Rouge::Lexers::Markdown.new
    formatter.format(lexer.lex(text))
  rescue
    # Fallback to plain text if highlighting fails
    text
  end
  
  def claude_model?(model)
    model.downcase.include?('claude')
  end
  
  def load_default_prompts
    if File.exist?(DEFAULT_PROMPTS_FILE)
      YAML.load_file(DEFAULT_PROMPTS_FILE) || {}
    else
      puts "Warning: default_prompts.yml not found at #{DEFAULT_PROMPTS_FILE}"
      {}
    end
  end
  
  def expand_command_substitutions(prompt)
    # Handle $(command) substitutions
    prompt.gsub(/\$\(([^)]+)\)/) do |match|
      command = $1
      result = `#{command}`.strip
      result
    end
  end
  
  def prompt_too_large?(model, prompt)
    # Rough token estimation: ~4 characters per token (conservative)
    estimated_tokens = prompt.length / 4
    
    # Get context limit for this model
    context_limit = get_model_context_limit(model)
    
    # Use 80% of context limit as safe threshold
    safe_limit = (context_limit * 0.8).to_i
    
    if estimated_tokens > safe_limit
      puts "\e[2mWarning: Prompt is large (~#{estimated_tokens} tokens)\e[0m"
      puts "\e[2m  Model '#{model}' context limit: #{context_limit} tokens\e[0m"
      puts "\e[2m  Recommended max: #{safe_limit} tokens (80% of limit)\e[0m"
      puts
      
      if estimated_tokens > context_limit
        puts "\e[91mError: Prompt exceeds model context limit!\e[0m"
        puts "\e[91m  This will likely fail or be truncated.\e[0m"
        puts
        return true
      else
        puts "\e[2m  Proceeding anyway... (may work but watch for truncation)\e[0m"
        puts
      end
    end
    
    false
  end
  
  def get_model_context_limit(model)
    # Try exact match first
    return MODEL_CONTEXT_LIMITS[model] if MODEL_CONTEXT_LIMITS[model]
    
    # Try partial matches for models with tags
    MODEL_CONTEXT_LIMITS.each do |model_pattern, limit|
      return limit if model.start_with?(model_pattern.split(':')[0])
    end
    
    # Unknown model - show warning and use conservative fallback
    puts "\e[2mWarning: Unknown model '#{model}'\e[0m"
    puts "\e[2m  Using conservative context limit: #{MODEL_CONTEXT_LIMITS['default']} tokens\e[0m"
    puts "\e[2m  Model may actually support more or fewer tokens\e[0m"
    puts
    
    MODEL_CONTEXT_LIMITS['default']
  end
  
  def get_ollama_ram_usage
    # Use ps to find all ollama processes and sum their RSS (memory usage)
    output = `ps -A -o pid,rss,comm | grep ollama | grep -v grep 2>/dev/null`.strip
    
    # Get free physical memory from vm_stat
    vm_stat = `vm_stat 2>/dev/null`
    page_size = 4096  # Default macOS page size
    free_ram_gb = 0
    
    if vm_stat.include?("Pages free:")
      # Parse vm_stat output to get free RAM
      pages_free = vm_stat.match(/Pages free:\s+(\d+)/)[1].to_i rescue 0
      free_ram_gb = (pages_free * page_size / 1024.0 / 1024.0 / 1024.0).round(2)
    end
    
    if output.empty?
      return "0GB (#{free_ram_gb}GB free)"
    end
    
    total_ram_kb = 0
    output.split("\n").each do |line|
      parts = line.strip.split
      next if parts.length < 3
      
      rss_kb = parts[1].to_i
      total_ram_kb += rss_kb if rss_kb > 0
    end
    
    if total_ram_kb > 0
      ram_gb = (total_ram_kb / 1024.0 / 1024.0).round(2)
      "#{ram_gb}GB (#{free_ram_gb}GB free)"
    else
      "0GB (#{free_ram_gb}GB free)"
    end
  rescue
    "N/A"
  end

  def execute_command_with_formatting(command_args, model, prompt)
    # Calculate and display token/character count
    char_count = prompt.length
    estimated_tokens = char_count / 4
    token_display = estimated_tokens >= 1000 ? "#{(estimated_tokens / 1000.0).round(1)}K" : estimated_tokens.to_s
    puts "\e[2mPrompt size: #{token_display} tokens (~#{char_count} chars)\e[0m"
    puts "\e[2mCalling #{command_args[0]} with model: #{model}\e[0m"
    puts
    
    start_time = Time.now
    spinner_active = true
    first_output = true
    in_thinking_block = false
    ram_monitor_active = true
    
    # Start RAM monitoring thread (only for ollama)
    ram_monitor_thread = if command_args[0] == "ollama"
      Thread.new do
        while ram_monitor_active
          ram_usage = get_ollama_ram_usage
          sleep 2  # Check every 2 seconds
        end
      end
    else
      nil
    end
    
    # Start spinner in background thread
    spinner_thread = Thread.new do
      spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
      spinner_index = 0
      
      while spinner_active
        elapsed = Time.now - start_time
        if command_args[0] == "ollama"
          ram_usage = get_ollama_ram_usage
          print "\r\e[2m#{spinner_chars[spinner_index]} Thinking... (#{format('%.1f', elapsed)}s) | RAM: #{ram_usage}\e[0m"
        else
          print "\r\e[2m#{spinner_chars[spinner_index]} Thinking... (#{format('%.1f', elapsed)}s)\e[0m"
        end
        $stdout.flush
        sleep 0.1
        spinner_index = (spinner_index + 1) % spinner_chars.length
      end
    end
    
    # Use Open3 to call command and stream the output
    Open3.popen2e(*command_args) do |stdin, stdout_err, wait_thread|
      stdin.close
      
      stdout_err.each_line do |line|
        if first_output
          # Stop spinner on first output
          spinner_active = false
          spinner_thread.join
          
          thinking_time = Time.now - start_time
          print "\r" + " " * 80 + "\r"  # Clear spinner line
          
          if command_args[0] == "ollama"
            final_ram = get_ollama_ram_usage
            puts "\e[2m Thought for #{format('%.1f', thinking_time)}s | RAM: #{final_ram}\e[0m"
          else
            puts "\e[2m Thought for #{format('%.1f', thinking_time)}s\e[0m"
          end
          
          puts "\e[2m─" * 60 + "\e[0m"
          puts
          first_output = false
        end
        
        # Check for thinking block markers (ollama specific)
        if command_args[0] == "ollama"
          if line.match(/Thinking\.\.\./)
            in_thinking_block = true
            print "\e[2m#{line}\e[0m"
          elsif line.match(/\.\.\.done thinking/)
            print "\e[2m#{line}\e[0m"
            in_thinking_block = false
          elsif in_thinking_block
            print "\e[2m#{line}\e[0m"
          else
            print highlight_markdown(line)
          end
        else
          # Apply markdown highlighting to the output
          print highlight_markdown(line)
        end
      end
      
      exit_status = wait_thread.value
      unless exit_status.success?
        spinner_active = false
        ram_monitor_active = false
        spinner_thread.join if spinner_thread.alive?
        ram_monitor_thread.join if ram_monitor_thread && ram_monitor_thread.alive? rescue nil
        puts "\n\e[2mError: #{command_args[0]} command failed with exit code #{exit_status.exitstatus}\e[0m"
        return false
      end
    end
    
    # Ensure spinner and RAM monitor are stopped
    spinner_active = false
    ram_monitor_active = false
    spinner_thread.join if spinner_thread.alive?
    ram_monitor_thread.join if ram_monitor_thread && ram_monitor_thread.alive?
    
    total_time = Time.now - start_time
    puts
    puts "\e[2m─" * 60 + "\e[0m"
    puts "\e[2m  Total time: #{format('%.1f', total_time)}s\e[0m"
    puts 
    
    # Stop the model to free up RAM (ollama specific)
    if command_args[0] == "ollama"
      puts "\e[2mStopping model to free RAM...\e[0m"
      system("ollama", "stop", model)
    end
    
    true
  rescue Errno::ENOENT
    spinner_active = false
    ram_monitor_active = false
    spinner_thread.join if spinner_thread.alive?
    ram_monitor_thread.join if ram_monitor_thread && ram_monitor_thread.alive? rescue nil
    puts "\e[2mError: #{command_args[0]} command not found. Please make sure #{command_args[0]} is installed and in your PATH.\e[0m"
    puts 
    false
  end

  def call_ollama(model, prompt)
    execute_command_with_formatting(["ollama", "run", "--hidethinking", model, prompt], model, prompt)
  end

  def call_claude(model, prompt)
    execute_command_with_formatting(["claude", "-p", prompt], model, prompt)
  end
end