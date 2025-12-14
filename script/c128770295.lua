local s,id=GetID()
function s.initial_effect(c)
	-- 룰상 다른 카드군으로도 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x764)
	c:RegisterEffect(e0)
	local e0b=e0:Clone()
	e0b:SetValue(0x765)
	c:RegisterEffect(e0b)

	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--② 일반/특수 소환 성공 시 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	--③ 선택 효과 (3개 중 1개)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.threetg)
	e3:SetOperation(s.threeop)
	c:RegisterEffect(e3)
end

------------------------------------------------
--① 패에서 특수 소환
function s.spfilter(c)
	return c:IsFaceup() and (c:IsSetCard(0x763) or c:IsSetCard(0x764) or c:IsSetCard(0x765))
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		or Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

------------------------------------------------
--② 덱 특수 소환
function s.ssfilter(c,e,tp)
	return (c:IsSetCard(0x763) or c:IsSetCard(0x764) or c:IsSetCard(0x765))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

------------------------------------------------
--③ 3분기 선택 효과
function s.ppxyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ)
end
function s.artifactfilter(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end
function s.distroidolfilter(c)
	return c:IsSetCard(0x765) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.threetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.threeop(e,tp,eg,ep,ev,re,r,rp)
	local sel=Duel.SelectEffect(tp,
		{true,aux.Stringid(id,3)}, -- 퍼펫 엑시즈 관련
		{true,aux.Stringid(id,4)}, -- 아티팩트 장착
		{true,aux.Stringid(id,5)}  -- 디스트로이돌 펜듈럼
	)
	if sel==1 then
		-- ● 퍼펫 엑시즈 대상, 덱에서 퍼펫 일반 몬스터 1장 소재로 겹침
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=Duel.SelectMatchingCard(tp,s.ppxyzfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
		if not tc then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local mg=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x763) and c:IsType(TYPE_NORMAL) end,tp,LOCATION_DECK,0,1,1,nil)
		if #mg>0 then
			Duel.Overlay(tc,mg)
		end
	elseif sel==2 then
		-- ● 아티팩트 묘지 장착
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local g1=Duel.SelectMatchingCard(tp,s.artifactfilter,tp,LOCATION_GRAVE,0,1,1,nil)
		if #g1==0 then return end
		local tc1=g1:GetFirst()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g2=Duel.SelectMatchingCard(tp,function(c) return c:IsFaceup() and c:IsSetCard(0x764) end,tp,LOCATION_MZONE,0,1,1,nil)
		if #g2==0 then return end
		Duel.Equip(tp,tc1,g2:GetFirst(),true)
		-- 장착 처리
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetValue(function(e,c) return c==g2:GetFirst() end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc1:RegisterEffect(e1)
	else
		-- ● 디스트로이돌 펜듈럼 2장 세팅 + 필드 전멸
		if Duel.CheckLocation(tp,LOCATION_PZONE,0) and Duel.CheckLocation(tp,LOCATION_PZONE,1) then
			local g=Duel.GetMatchingGroup(s.distroidolfilter,tp,LOCATION_DECK,0,nil)
			if #g>=2 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
				local sg=g:Select(tp,2,2,nil)
				for tc in sg:Iter() do
					Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
				end
				local fg=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
				if #fg>0 then
					Duel.Destroy(fg,REASON_EFFECT)
				end
			end
		end
	end
end
