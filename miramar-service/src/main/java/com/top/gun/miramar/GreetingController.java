package com.top.gun.miramar;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class GreetingController
{
  @RequestMapping("/greeting")
  public String greeting(@RequestParam(value = "name", required = false, defaultValue = "World") String name,
                         Model model)
  {
    name = MaverickUtils.makeFly(name);
    model.addAttribute("name", name);
    return "greeting";
  }
}
