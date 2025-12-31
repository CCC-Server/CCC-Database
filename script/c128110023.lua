--SU(서브유니즌) 옴니 핀테일
--Setcode: 0xc81
local s,id=GetID()
s.listed_series={0xc81}

-- zone bitmask -> seq(0~4) (bit/bit32 없이 안전)
local function zone_to_seq(zone)
	local seq=0
	while zone>1 do
		zone=math.floor(zone/2)
		seq=seq+1
	end
	return seq
end
local function pow2(n) return 2^n end

function s.initial_effect(c)
	c:EnableReviveLimit()

	--==================================================
	-- Fusion Materials: 3 "SU" monsters, including a Fusion Monster
	-- (fcheck 방식 제거 → 코어 호환 최강 / 융합소환 정상)
	--==================================================
	Fusion.AddProcMix(c,true,true,s.sufusionfilter,s.sufilter,s.sufilter)

	--==================================================
	-- Must first be Fusion Summoned, or Special Summoned (from Extra Deck) by its own procedure
	--==================================================
	local eex=Effect.CreateEffect(c)
	eex:SetType(EFFECT_TYPE_SINGLE)
	eex:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	eex:SetCode(EFFECT_SPSUMMON_CONDITION)
	eex:SetRange(LOCATION_EXTRA)
	eex:SetValue(s.ex_splimit)
	c:RegisterEffect(eex)

	--==================================================
	-- Alt Summon Procedure: Tribute "SU" (hand/field) total Levels = 12
	--==================================================
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)

	--==================================================
	-- (1) If Special Summoned: apply both damage mods this turn (OPT)
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.eff1op)
	c:RegisterEffect(e1)

	--==================================================
	-- (2) Quick: move or swap -> SS 2 "SU" from GY/banished -> shuffle End Phase (OPT)
	--==================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)

	--==================================================
	-- (3) Immune to opponent's on-field activated effects, except those in this card's column
	--==================================================
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
end

--========================
-- Fusion filters
--========================
function s.sufilter(c,fc,sumtype,tp)
	return c:IsMonster() and c:IsSetCard(0xc81)
end
function s.sufusionfilter(c,fc,sumtype,tp)
	return c:IsMonster() and c:IsSetCard(0xc81) and c:IsType(TYPE_FUSION)
end

-- Extra Deck에서의 소환 제한: 융합소환 or 이 카드의 자체 소환절차(e0)만 허용
function s.ex_splimit(e,se,sp,st)
	if st==SUMMON_TYPE_FUSION then return true end
	if se and se:GetHandler()==e:GetHandler() then return true end
	return false
end

--========================
-- Alt Summon (Lv sum 12 tribute)
--========================
function s.sprfilter(c)
	return c:IsSetCard(0xc81) and c:IsType(TYPE_MONSTER) and c:IsLevelAbove(1) and c:IsReleasableByEffect()
end
function s.rescon(sg,e,tp,mg,ft)
	if sg:GetSum(Card.GetLevel)~=12 then return false end
	if ft>0 then return true end
	return sg:IsExists(Card.IsLocation,1,nil,LOCATION_MZONE)
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local ft=Duel.GetLocationCountFromEx(tp,tp,nil,c)
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	if #g==0 then return false end
	return aux.SelectUnselectGroup(g,e,tp,1,#g,function(sg,ee,tpp,mg) return s.rescon(sg,ee,tpp,mg,ft) end,0)
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local ft=Duel.GetLocationCountFromEx(tp,tp,nil,c)
	local g=Duel.GetMatchingGroup(s.sprfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,#g,function(sg,ee,tpp,mg) return s.rescon(sg,ee,tpp,mg,ft) end,1,tp,HINTMSG_RELEASE)
	if not sg then return end
	c:SetMaterial(sg)
	Duel.Release(sg,REASON_COST+REASON_MATERIAL)
end

--========================
-- (1) Damage mods (코어에 GetBattleDamagePlayer 없음 → ep/ev 사용)
--========================
local function involves_su(tp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if a and a:IsControler(tp) and a:IsSetCard(0xc81) then return true end
	if d and d:IsControler(tp) and d:IsSetCard(0xc81) then return true end
	return false
end

function s.eff1op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetOperation(function(ee,tpp,eg1,ep1,ev1,re1,r1,rp1)
		if ep1~=1-tp then return end
		if not involves_su(tp) then return end
		if ev1>0 then Duel.ChangeBattleDamage(ep1,ev1*2) end
	end)
	Duel.RegisterEffect(e1,tp)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e2:SetReset(RESET_PHASE+PHASE_END)
	e2:SetOperation(function(ee,tpp,eg1,ep1,ev1,re1,r1,rp1)
		if ep1~=tp then return end
		if not involves_su(tp) then return end
		if ev1>0 then Duel.ChangeBattleDamage(ep1,math.floor(ev1/2)) end
	end)
	Duel.RegisterEffect(e2,tp)
end

--========================
-- (2) Move/Swap -> SS 2 -> Shuffle End Phase
--========================
function s.swapfilter(c)
	return c:IsSetCard(0xc81) and c:IsFaceup() and c:IsInMainMZone()
end
function s.spfilter(c,e,tp)
	if not (c:IsSetCard(0xc81) and c:IsType(TYPE_MONSTER)) then return false end
	if c:IsLocation(LOCATION_REMOVED) and not c:IsFaceup() then return false end
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local canmove=false
	if c:IsInMainMZone() then
		for seq=0,4 do
			if seq~=c:GetSequence() and Duel.CheckLocation(tp,LOCATION_MZONE,seq) then
				canmove=true
				break
			end
		end
	end
	local canswap=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	if chk==0 then
		if not (canmove or canswap) then return false end
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsControler(1-tp) or not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end

	local canmove=false
	local disable=0
	if c:IsInMainMZone() then
		for seq=0,4 do
			if seq~=c:GetSequence() and Duel.CheckLocation(tp,LOCATION_MZONE,seq) then
				canmove=true
			end
			if (not Duel.CheckLocation(tp,LOCATION_MZONE,seq)) or seq==c:GetSequence() then
				disable = disable + pow2(seq)
			end
		end
	end

	local canswap=Duel.IsExistingMatchingCard(s.swapfilter,tp,LOCATION_MZONE,0,1,c)
	local op=0
	if canmove and canswap then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif canmove then
		op=0
	elseif canswap then
		op=1
	else
		return
	end

	local moved=false
	if op==0 then
		local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,disable)
		local nseq=zone_to_seq(zone)
		if Duel.CheckLocation(tp,LOCATION_MZONE,nseq) then
			Duel.MoveSequence(c,nseq)
			moved=true
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=Duel.SelectMatchingCard(tp,s.swapfilter,tp,LOCATION_MZONE,0,1,1,c):GetFirst()
		if tc and c:IsLocation(LOCATION_MZONE) and tc:IsLocation(LOCATION_MZONE) then
			Duel.SwapSequence(c,tc)
			moved=true
		end
	end
	if not moved then return end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
	if #g<2 then return end

	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,2,2,nil)
	if #sg==0 then return end
	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	local fid=c:GetFieldID()
	for tc in aux.Next(sg) do
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,fid)
	end
	sg:KeepAlive()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCountLimit(1)
	e1:SetLabel(fid)
	e1:SetLabelObject(sg)
	e1:SetCondition(s.retcon)
	e1:SetOperation(s.retop)
	Duel.RegisterEffect(e1,tp)
end

function s.retfilter(c,fid)
	return c:GetFlagEffectLabel(id)==fid
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if not g or not g:IsExists(s.retfilter,1,nil,e:GetLabel()) then
		if g then g:DeleteGroup() end
		e:Reset()
		return false
	end
	return true
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if not g then return end
	local tg=g:Filter(s.retfilter,nil,e:GetLabel())
	if #tg>0 then
		Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	g:DeleteGroup()
end

--========================
-- (3) Column immunity
--========================
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetHandler()
	if te:GetOwnerPlayer()==e:GetHandlerPlayer() then return false end
	local loc=te:GetActivateLocation()
	if (loc & LOCATION_ONFIELD)==0 then return false end
	if not te:IsActivated() then return false end
	return not c:IsColumn(tc)
end
