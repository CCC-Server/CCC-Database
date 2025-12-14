-- 네메시스 디스트로이돌 펜듈럼 몬스터
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 1턴 1회 제한
	c:SetUniqueOnField(1,0,id)

	-- 펜듈럼
	Pendulum.AddProcedure(c)

	------------------------------------------------------
	-- [펜듈럼 효과] ①
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id+100)
	e1:SetCondition(s.pencon)
	e1:SetTarget(s.pentg)
	e1:SetOperation(s.penop)
	c:RegisterEffect(e1)

	------------------------------------------------------
	-- [몬스터 효과] ① 엑스트라 덱에서 펜듈럼 몬스터 1장 패로 가져오기
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+200)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	------------------------------------------------------
	-- [몬스터 효과] ② 효과로 파괴 시 LP 회복 후 흑의 노래 펜듈럼 존
	------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.reccon)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end

-- ======================================
-- 펜듈럼 효과 조건
-- ======================================
-- [펜듈럼 효과] 수정
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.matfilter(c)
	return c:IsSetCard(0x765) and c:IsCanBeFusionMaterial() and c:IsAbleToGrave()
end

function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x765)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg)
end

function s.penop(e,tp,eg,ep,ev,re,r,rp)
	-- Step 1: 패/필드에서 융합 소재 후보를 수집
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	if #mg==0 then return end

	-- Step 2: 융합 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
	local tc=sg:GetFirst()
	if not tc then return end

	-- Step 3: 해당 몬스터의 융합 소재를 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
	if #mat==0 then return end

	-- Step 4: 묘지로 보내고 융합 소환
	Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	tc:SetMaterial(mat)
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end


-- ======================================
-- 몬스터 효과 ① 엑스트라 덱에서 펜듈럼 몬스터 패로 가져오기
-- ======================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_FUSION+REASON_MATERIAL)
		or e:GetHandler():IsLocation(LOCATION_EXTRA)
end

function s.thfilter(c)
	return c:IsSetCard(0x765) and c:IsType(TYPE_PENDULUM) and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ======================================
-- 몬스터 효과 ② LP 회복 + 흑의 노래 펜듈럼 존
-- ======================================
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(500)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)

	-- 엑스트라 덱에서 앞면 표시로 존재하는 "흑의 노래" 검색
	local g=Duel.GetMatchingGroup(function(c)
		return c:IsCode(128770336) and c:IsFaceup()
	end, tp, LOCATION_EXTRA, 0, nil)

	if #g==0 then return end  -- 없으면 종료

	-- 펜듈럼 존 빈 칸 확인
	local seq=nil
	if Duel.CheckLocation(tp, LOCATION_PZONE, 0) then
		seq=0
	elseif Duel.CheckLocation(tp, LOCATION_PZONE, 1) then
		seq=1
	end
	if seq==nil then return end  -- 빈 존이 없으면 종료

	-- 카드 존재 확인 후 이동
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
