--Mist Valley Behemoth Mist Wurm
--안개 골짜기의 대괴조 미스트 우옴
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_WIND),1,1,Synchro.NonTuner(nil),2,99)
	c:EnableReviveLimit()
	--Bounce up to 3 cards
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F) -- "If" but likely optional in TCG? User said "If...: Target". Usually Optional. Let's make it TRIGGER_O.
	-- Wait, "If this card is Synchro Summoned: Target...". This is mandatory if it doesn't say "You can". 
	-- User text: "(1) If this card is Synchro Summoned: Target up to 3 cards..." 
	-- Missing "You can". Implies Mandatory Trigger. 
	-- However, "Target up to 3" implies you can choose 0? No, usually implies 1 to 3.
	-- If it's mandatory but "up to 3", you must target at least 1 if available? 
	-- Let's check "Trishula". "You can".
	-- Let's check "Mist Wurm" (Original). "If this card is Synchro Summoned: Target up to 3 cards your opponent controls; return those targets to the hand." 
	-- Original Mist Wurm is Mandatory Trigger with "up to 3". 
	-- Ruling: You can choose 0? No, if mandatory, you must select valid targets. But "up to" is tricky in mandatory.
	-- Actually, Original Mist Wurm text has errata. Modern: "If this card is Synchro Summoned: Target up to 3 cards your opponent controls; return them to the hand." 
	-- It is indeed mandatory. But rulings say you can target 0? No, usually you target 1-3. 
	-- I will implement as TRIGGER_O (Optional) because "up to 3" usually suggests player choice, or strictly follow text as Mandatory.
	-- Given the "You can only use... (2)" clause but not (1), and the powerful "Cannot respond", it feels like a boss monster effect.
	-- I will use TRIGGER_O (Optional) to be safe for a custom card, or TRIGGER_F if strictly following text. 
	-- "If ... : Target ..." (Mandatory). 
	-- But let's look at the user's text again. "(1) If this card is Synchro Summoned: Target ...". 
	-- I'll make it Optional (TRIGGER_O) for better playability (don't want to bounce own cards if forced? Oh it says "opponent controls").
	-- I will stick to TRIGGER_O because unintended mandatory triggers are annoying.
	-- Correction: Original Mist Wurm is Optional in OCG/TCG modern text? 
	-- "When this card is Synchro Summoned: Return up to 3...". Original was mandatory. 
	-- I will set it as TRIGGER_O ("You can") to avoid forcing activation, although text didn't explicitly say "You can". 
	-- Re-reading user text: "If this card is Synchro Summoned: Target up to 3...". 
	-- Standard PSCT for Optional is "If ... : You can target ...".
	-- Standard PSCT for Mandatory is "If ... : Target ...".
	-- I will implement as **Mandatory** because the text lacks "You can".
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--De-Synchro Swarm
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--OATH counter
	Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,s.counterfilter)
end
s.listed_series={0x37}

-- Oath Filter: Count only non-WIND Special Summons
function s.counterfilter(c)
	return c:IsAttribute(ATTRIBUTE_WIND)
end

-- (1) Condition
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

-- (1) Target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToHand() end
	if chk==0 then return true end -- Mandatory: Activates even if 0 targets? "Target up to 3" usually requires at least 1 if available.
	-- If mandatory, and opponent has cards, must target.
	local g=Duel.GetMatchingGroup(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local sg=g:Select(tp,1,3,nil)
		Duel.SetTargetCard(sg)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,sg,#sg,0,0)
		-- Prevent response by targeted cards
		Duel.SetChainLimit(s.chainlm(sg))
	end
end

-- Chain Limit: Opponent cannot activate effects of TARGETED cards
function s.chainlm(g)
	return function(e,rp,tp)
		return not g:IsContains(e:GetHandler())
	end
end

-- (1) Operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end

-- (2) Condition: Synchro Summoned
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

-- (2) Cost: Return to Extra Deck + Check Oath
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsAbleToExtraAsCost() 
		and Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 
	end
	Duel.SendtoDeck(c,nil,0,REASON_COST)
	-- Oath Restriction
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,2),nil)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsAttribute(ATTRIBUTE_WIND)
end

-- (2) Target Selection Logic
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x37) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and c:HasLevel()
end

function s.rescon(sg,e,tp,mg)
	return sg:GetSum(Card.GetLevel)==9 and sg:GetClassCount(Card.GetCode)==#sg
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
	if chk==0 then return aux.SelectUnselectGroup(g,e,tp,1,3,s.rescon,0) end -- Check if valid combination exists
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,3,s.rescon,1,tp,HINTMSG_SPSUMMON)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg,#sg,0,0)
end

-- (2) Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end