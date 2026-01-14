-- 데드웨어 제로데이 익스플로잇
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 상대가 드로우 이외로 카드를 패에 넣었을 경우 발동 (자신의 카드가 넘어간 경우 포함)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

	-- ②: 상대가 몬스터를 소환했을 경우 발동 (상대 몬스터와 함께 싱크로)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.syncon2)
	e2:SetTarget(s.syntg2)
	e2:SetOperation(s.synop2)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	-- ③: 엑시즈 존재 시 상대 몬스터 효과 발동 시 발동 (묘지 소생 및 소재화)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.xyzcon3)
	e3:SetTarget(s.xyztg3)
	e3:SetOperation(s.xyzop3)
	c:RegisterEffect(e3)
end

-- ① 효과 로직: 상대 패 추가 반응 (수정됨)
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	-- 드로우 페이즈 제외, 이벤트 그룹(eg) 중 상대(1-tp)의 패로 들어간 카드가 있는지 확인
	return not Duel.IsPhase(PHASE_DRAW) and eg:IsExists(Card.IsControler,1,nil,1-tp)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thfilter1(c)
	return c:IsSetCard(0xc55) and c:IsMonster() and c:IsAbleToHand()
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 덱/묘지에서 '데드웨어' 1장을 상대 패에 넣음
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.BreakEffect()
			-- 상대(1-tp)의 패로 보내고 확인 및 셔플 (별의 금화 로직)
			if Duel.SendtoHand(g,1-tp,REASON_EFFECT)>0 then
				Duel.ConfirmCards(tp,g)
				Duel.ShuffleHand(1-tp)
			end
		end
	end
end

-- ② 효과 로직: 소환 반응 싱크로 (액마그네 로직)
function s.syncon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.scfilter(c,mg)
	return c:IsSetCard(0xc55) and c:IsSynchroSummonable(nil,mg)
end
function s.matfilter(tc,c,tp)
	if not tc:IsFaceup() or not tc:IsCanBeSynchroMaterial() then return false end
	-- 상대 몬스터에게 일시적 소재 권한 부여 후 체크
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SYNCHRO_MATERIAL)
	tc:RegisterEffect(e1,true)
	local mg=Group.FromCards(c,tc)
	local res=Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	e1:Reset()
	return res
end
function s.syntg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.matfilter(chkc,e:GetHandler(),tp) end
	if chk==0 then return Duel.IsExistingTarget(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler(),e:GetHandler(),tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
	Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,e:GetHandler(),e:GetHandler(),tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.synop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SYNCHRO_MATERIAL)
		tc:RegisterEffect(e1,true)
		local mg=Group.FromCards(c,tc)
		local g=Duel.GetMatchingGroup(s.scfilter,tp,LOCATION_EXTRA,0,nil,mg)
		if #g>0 then
			local sc=g:Select(tp,1,1,nil):GetFirst()
			-- 소환 후 소재 권한 리셋
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_SPSUMMON_SUCCESS)
			e2:SetOperation(function(e) e:GetLabelObject():Reset() e:Reset() end)
			e2:SetLabelObject(e1)
			sc:RegisterEffect(e2,true)
			Duel.SynchroSummon(tp,sc,nil,mg)
		else
			e1:Reset()
		end
	end
end

-- ③ 효과 로직: 엑시즈 소재로 흡수
function s.xyzcon3(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 몬스터 효과 발동 시 + 내 필드에 엑시즈 존재
	return rp==1-tp and re:IsMonsterEffect()
		and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_XYZ)
end
function s.xyztg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local tc=re:GetHandler()
	if chkc then return chkc==tc end
	if chk==0 then return tc:IsRelateToEffect(re) and tc:IsCanBeXyzMaterial(nil)
		and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_XYZ) end
	Duel.SetTargetCard(tc) -- 효과를 발동한 몬스터를 대상으로 지정
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end
function s.xyzop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget() -- 효과 발동 몬스터
	local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_MZONE,0,nil,TYPE_XYZ)
	if #g>0 and tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local xc=g:Select(tp,1,1,nil):GetFirst() -- 내 엑시즈 몬스터 선택
		if xc then
			local mg=Group.FromCards(c,tc)
			Duel.Overlay(xc,mg) -- 묘지의 이 카드와 상대 몬스터를 겹침
		end
	end
end